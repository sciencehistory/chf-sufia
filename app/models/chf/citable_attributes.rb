module CHF

  # Extract attributes more common to reference manager/citation models.
  #
  # Using the CSL-data model, including some classes from the citeproc gem.
  #
  # For certain museum/archival "objects", we treat them as photographs taken here,
  # rather than trying to cite the original object.  We have two implementaiton sub-classes,
  # so the local photograph treatment can 'override' things from standard treatment.
  # We use inhertance with TreatAsLocalPhotograph inheriting from StandardTreatment, which
  # may be non-ideal as we ARE doing this to inherit implementation, but makes implementation
  # a lot easier, and we'll keep the implementation classes for non-public use.
  class CitableAttributes
    attr_reader :work, :implementation

    def initialize(work)
      @work = work
      @implementation = treat_as_local_photograph? ? TreatAsLocalPhotograph.new(@work) : StandardTreatment.new(@work)
    end

    # Photos of objects we want to cite as an Institute photo, not the object
    def treat_as_local_photograph?
      @treat_as_local_photograph ||= work.division == "Museum" && ! work.resource_type.include?("Text")
    end


    delegate :authors, :publisher, :publisher_place, :date,
      :medium, :archive_location, :archive, :archive_place, :title, :csl_id, :abstract, :csl_type,
      to:  :implementation

    # A _hash_ (not a serialized json string) representing in the csl-data.json
    # format. https://github.com/citation-style-language/schema/blob/master/csl-data.json
    def as_csl_json
      {
        type: csl_type,
        title: title,
        id: csl_id,
        abstract: abstract,
        author: authors.collect(&:to_citeproc),
        issued: date ? date.to_citeproc : nil,
        publisher: publisher,
        "publisher-place": publisher_place,
        medium: medium,
        "URL": "https://digital.sciencehistory.org/#{work.id}",
        archive: archive,
        'archive-place': archive_place,
        archive_location: archive_location,
      }.compact
    end

    def to_csl_json
      JSON.dump(as_csl_json)
    end

    protected

    def implementation
      @implementation
    end

    class StandardTreatment
      attr_reader :work
      def initialize(work)
        @work = work
      end

      def title
        work.title && work.title.first
      end

      def csl_id
        "scihist#{work.id}"
      end

      # Map to valid csl type in schema https://github.com/citation-style-language/schema/blob/master/csl-data.json
      # When in doubt we tend to default to 'manuscript', cause that usually ends up getting cited correctly
      # for archival material.
      def csl_type
        if work.genre_string.include?('Manuscripts')
          return "manuscript"
        elsif (work.genre_string & ['Rare books', 'Sample books']).present?
          return "book"
        elsif work.genre_string.include?('Documents') && work.title.any? { |v| v=~ /report/i }
          return "report"
        elsif  work.division == "Archives"
          # if it's not one of above known to use archival metadata, and it's in
          # Archives, insist on Manuscript.
          return "manuscript"
        elsif (work.genre_string & %w{Paintings}).present?
          return "graphic"
        elsif work.genre_string.include?('Slides')
          return "graphic"
        elsif work.genre_string.include?('Encyclopedias and dictionaries')
          return "book"
        else
          return "manuscript"
        end
      end

      def abstract
        work.description.present? ? ActionView::Base.full_sanitizer.sanitize(work.description.join(" ")) : nil
      end

      # an array of CiteProc::Name objects, suitable for using as cited creator(s)
      def authors
        memoize(:authors) do
          # ordered list of maker fields we're willing to use for author, when we
          # find one with elements, we stop and use those.
          first_present_field_values(%w{creator_of_work author contributor artist photographer engraver}).collect do |str_name|
            parse_name(str_name)
          end
        end
      end

      def publisher
        memoize(:publisher) do
          # ordered list of fields we're willing to look for publisher, if we find
          # one we take only the FIRST thing, and use that.
          raw_name = first_present_field_values(%w{publisher printer printer_of_plates}).first
          # use parse name to print out in direct order
          raw_name ? parse_name(raw_name).print : nil
        end
      end

      def publisher_place
        memoize(:publisher_place) do
          work.place_of_publication.present? ? normalize_place( work.place_of_publication.first ) : nil
        end
      end

      # Returns a single CiteProc::Date object, which is capable of being a single date
      # or a single range, possibly having a "circa" qualifier, and dates can have non-defined month or day.
      # Can not return multiple distinct dates though, so we try to collapse them when we have them.
      def date
        memoize(:date) do
          if work.date_of_work.present?
            cite_proc_dates = work.date_of_work.collect { |d| local_date_to_citeproc_date(d) }.compact

            min_date_part = cite_proc_dates.collect(&:date_parts).flatten.min
            max_date_part = cite_proc_dates.collect(&:date_parts).flatten.max

            if min_date_part.nil? && max_date_part.nil?
              nil
            elsif min_date_part == max_date_part
              ::CiteProc::Date.new(min_date_part.to_a.compact)
            else
              ::CiteProc::Date.new([min_date_part.to_a.compact, max_date_part.to_a.compact])
            end
          end
        end
      end

      def medium
        memoize(:medium) do
          work.medium.present? ? work.medium.collect(&:downcase).join(", ") : nil
        end
      end

      # We decided NOT to include series/subseries in citation, just collection and physical lcoation
      def archive_location
        memoize(:archive_location) do
          if work.division == "Archives"
            parts = []

            parts << work.in_collections.first.title.first if work.in_collections.present?
            # parts.concat item.series_arrangement.to_a if item.series_arrangement.present?
            #parts = [parts.join("; ")] if parts.present?
            parts << CHF::Utils::ParseFields.display_physical_container(work.physical_container) if work.physical_container.present?
            parts.collect(&:presence).compact.join(', ')
          end
        end
      end

      def archive_place
        if work.division == "Archives" || work.division == "Museum"
          "Philadelphia"
        end
      end

      def archive
        if work.division == "Archives" || work.division == "Museum"
          "Science History Institute"
        end
      end

      protected

      # we use our own :memoize instead of `||=` so it can memoize nil
      def memoize(key)
        key = key.to_sym
        @__memoized = {}
        unless @__memoized.has_key?(key)
          @__memoized[key] = yield
        end
        @__memoized[key]
      end


      # _single_ local date object to a citeproc date
      def local_date_to_citeproc_date(date)
        # year, month, date
        start_part = date.start.presence && date.start.scan(/\d+/).slice(0..2)
        finish_part = date.finish.presence && date.finish.scan(/\d+/).slice(0..2)

        args = []
        args << start_part if start_part
        args << finish_part if finish_part
        return nil if args.empty?

        CiteProc::Date.new(args).tap do |citeproc_date|
          #TODO we need "circa" sometimes
        end
      end

      # first_present_field_values(["publisher", "printer", "printer_of_places"])
      # will send the array of values of the first of those that is non-empty, or
      # an empty array if they are all empty.
      def first_present_field_values(fields)
        first_present = fields.find { |attr| work.send(attr).present? }
        first_present ? work.send(first_present) : []
      end

      # Try to change "New York (State) -- New York" into "New York, New York"
      # Can't quite do it, (State)
      def normalize_place(str)
        if str =~ /--/
          str.split("--").reverse.join(", ")
        else
          str
        end
      end

      # returns a Citeproc::Name object, which is composed of possible
      # given, family, and suffix; or just literal.
      #
      # Tries to parse the AACR2-style names we have. Not knowing if it's a personal
      # or corporate name makes this hard, if it's personal comma means inverted family, given.
      # If it's corporate... comma may just be part of name. We're going to get it wrong, I guarantee.
      def parse_name(str)
        str = str.dup
        date_suffix = /, (active )?\d\d\d\d-(\d\d\d\d)?|-\d\d\d\d\Z/

        # remove 'inc'
        str.sub!(/, inc\. */, '')

        if str =~ date_suffix
          # looks like a personal name with birth/death dates, remove em and parse
          str.sub!(date_suffix, '')
          ::CiteProc::Name.new(Namae::Name.parse(str)) || CiteProc::Name.new(literal: str)
        elsif str =~ /[A-Z].*, *[A-Z]/
          # looks like a personal name in inverted form
          ::CiteProc::Name.new(Namae::Name.parse(str)) || CiteProc::Name.new(literal: str)
        else
          # probably a corporate name
          ::CiteProc::Name.new(literal: str)
        end
      end
    end

    class TreatAsLocalPhotograph < StandardTreatment
      def csl_type
        "graphic"
      end

      def authors
        memoize(:authors) do
          [CiteProc::Name.new(literal: "Science History Institute")]
        end
      end

      def medium
        "photograph".freeze
      end

      def date
        # I think this is best way we got to get date of photo
        date_of_photo = work.date_uploaded
        date_of_photo ? CiteProc::Date.new([date_of_photo.year, date_of_photo.month, date_of_photo.day]) : nil
      end

      def publisher
        nil
      end

      def publisher_place
        nil
      end

      def archive_location
        nil
      end
    end

  end
end