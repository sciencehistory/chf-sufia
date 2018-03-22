module CHF
  # https://github.com/aurimasv/translators/wiki/RIS-Tag-Map-(narrow)
  class RisSerializer
    RIS_LINE_END = "\r\n"
    RIS_END_RECORD = "ER  -#{RIS_LINE_END}"

    attr_reader :work_presenter, :collection, :parent_work

    def initialize(work_presenter, collection: nil, parent_work: nil)
      @work_presenter = work_presenter
      @collection = collection
      @parent_work = parent_work
    end

    def citable_attributes
      @citable_attributes ||= CHF::CitableAttributes.new(work_presenter, collection: collection, parent_work: parent_work)
    end

    def self.formatted_ris_date(year:, month: nil, day: nil, extra: nil)
      str = year.to_s

      str += "/"
      if month.present?
        str += "%02i" % month.to_i
      end

      str += "/"
      if day.present?
        str += "%02i" % day.to_i
      end

      str += "/"
      if extra.present?
        str += extra
      end

      str
    end

    # RIS fields not including type. Values can be arrays or single elements.
    def ris_hash
      return @ris_hash if defined?(@ris_hash)

      @ris_hash ||= {
        # Theoretically "DB" is 'name of database' and "DP" is "database provider"
        # Different software uses one or the other for "Archive:". We use the plain
        # institute name for both, in line with rebrand style guide.
        "DB" => "Science History Institute",
        "DP" => "Science History Institute",
        # M2 is 'extra' notes field
        "M2" => m2,

        # If there's a container title, it's in TI, and specific title is in T2.
        "TI" => citable_attributes.container_title.present? ? citable_attributes.container_title : citable_attributes.title,
        "T2" => citable_attributes.container_title.present? ? citable_attributes.title : nil,

        "ID" => work_presenter.id,
        "AU" => citable_attributes.authors_formatted,
        "PB" => citable_attributes.publisher,
        "CY" => citable_attributes.publisher_place,
        "DA" => ris_date,
        "YR" => ris_date_year,

        "M3" => citable_attributes.medium,

        # archival location is according to wikipedia "AV". Endnote uses "VL" (volume) for this though.
        # And Zotero uses "AN" (accession number)!
        "AV" => citable_attributes.archive_location,
        "VL" => citable_attributes.archive_location,
        "AN" => citable_attributes.archive_location,

        "UR" => citable_attributes.url,

        "AB" => citable_attributes.abstract,
        "KW" => kw,
        "LA" => la,
      }
    end

    def to_ris
      return @to_ris if defined?(@to_ris)

      @to_ris ||= begin
        lines = []
        # TY needs to be first
        lines << "TY  - #{ris_type}"

        ris_hash.each_pair do |tag, value|
          Array(value).each do |v|
            lines << "#{tag}  - #{v}"
          end
        end

        lines << RIS_END_RECORD
        lines.join(RIS_LINE_END)
      end
    end

    def genre_string
      work_presenter.genre_string || []
    end

    # Limited ability to map to RIS types -- 'manuscript' type seems to get
    # the best functionality for archival fields in most software, so we default to
    # that and use that in many places maybe we COULD have something more specific.
    def ris_type
      return @ris_type if defined?(@ris_type)

      @ris_type ||= begin
        if genre_string.include?('Manuscripts')
          "MANSCPT"
        elsif (genre_string & ['Personal correspondence', 'Business correspondence']).present?
          "PCOMM"
        elsif (genre_string & ['Rare books', 'Sample books']).present?
          "BOOK"
        elsif genre_string.include?('Documents') && item.title.any? { |v| v=~ /report/i }
          "RPRT"
        elsif  work_presenter.division == ["Archives"]
          # if it's not one of above known to use archival metadata, and it's in
          # Archives, insist on Manuscript.
          "MANSCPT"
        elsif (genre_string & %w{Paintings}).present?
          "ART"
        elsif genre_string.include?('Slides')
          "SLIDE"
        elsif genre_string.include?('Encyclopedias and dictionaries')
          "ENCYC"
        else
          "MANSCPT"
        end
      end
    end

    # zotero 'extra'. endnote?
    def m2
      return @m2 if defined?(@m2)

      @m2 ||= begin
        "Courtesy of Science History Institute." +
          # rights statement
          if work_presenter.rights.present?
            "  Rights: " + work_presenter.rights.collect do |id|
              CurationConcerns::LicenseService.new.label(id)
            end.join(", ") + (work_presenter.rights_holder.present? ? ", #{item.rights_holder}" : "")
          else
            ""
          end
      end
    end

    # date in RIS format
    def ris_date
      return @ris_date if defined?(@ris_date)

      @ris_date ||= begin
        if work_presenter.date_of_work_models.present?
          date = work_presenter.date_of_work_models.first
          if date.start
            parts = date.start.scan(/\d+/)
            self.class.formatted_ris_date(year: parts.first, month: parts.second, day: parts.third, extra: date.note)
          end
        end
      end
    end

    def ris_date_year
      return @ris_date_year if defined?(@ris_date_year)

      @ris_date_year ||= begin
        work_presenter.date_of_work_models.try(:first).try(:start) =~ /\A(\d\d\d\d)/
        $1
      end
    end

    # subjects aren't in CitableAttributes yet, maybe they should be if we
    # end up using csl-data for zotero export ever.
    #
    # Returns an array cause RIS kw is a rare repeatable one.
    def kw
      return @kw if defined?(@kw)

      @kw ||= begin
        work_presenter.subject
      end
    end

    # languages aren't in CitableAttributes yet, maybe they should be if we
    # end up using csl-data for zotero export ever.
    #
    # RIS la is not repeatable, we join multiple with comma
    def la
      return @la if defined?(@la)

      @la ||= work_presenter.language.join(", ")
    end
  end
end
