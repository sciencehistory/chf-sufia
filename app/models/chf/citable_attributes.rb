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
  #
  # NOTE WELL: This class takes a work _presenter_, a GenericWorkShowPresenter, and is
  # used at display time. We tried to do it at index time, it didn't work out.
  #
  # An existing CollectionShowPresenter needs to be passed in, if it is to be used in citations.
  # Same with parent_work. The citations are far from perfect here.
  #
  # For date ranges and circa dates, will include a formatted literal in csl output,
  # unless `edge_case_date_literals: false`.
  class CitableAttributes
    attr_reader :work, :collection, :implementation

    # collection is a CollectionShowPresenter,optional, for including in citation for archival
    # parent_work if present used for citation container title.
    #
    # Both are optional, and will be looked up from presenter, but you can pass in
    # if you have a more efficient place to get them, you've already fetched them.
    def initialize(work,
                    collection: nil,
                    parent_work: nil,
                    edge_case_date_literals: true)
      @work = work
      @collection = collection.nil? ? work.in_collection_presenters.first : collection
      @parent_work = parent_work.nil? ? work.parent_work_presenters.first : parent_work
      @edge_case_date_literals = !!edge_case_date_literals

      if treat_as_oral_history?
        @implementation = TreatAsOralHistory.new(@work, collection: @collection, parent_work: @parent_work)
      elsif treat_as_local_photograph?
        @implementation = TreatAsLocalPhotograph.new(@work, collection: @collection, parent_work: @parent_work)
      else
        @implementation = StandardTreatment.new(@work, collection: @collection, parent_work: @parent_work)
      end

    end

    # Photos of objects we want to cite as an Institute photo, not the object
    def treat_as_local_photograph?
      @treat_as_local_photograph ||= work.division && work.division.include?("Museum") &&
        work.resource_type && work.resource_type.include?("Physical Object") &&
        work.resource_type.count == 1
    end

    # Oral histories
    def treat_as_oral_history?
      work.genre_string != nil && work.genre_string.include?('Oral histories')
    end


    # ruby-csl can't really do date ranges yet.
    # And the CSL chicago style isn't marking "circa" dates for some reason.
    # So for these cases, we'll format it ourselves  and send it along as a literal.
    # We're not formatting as well as CSL spec, just something good enough -- we resort to just years
    # when we do this, ignoring month/day.
    def formatted_date_literal
      open_date = date.parts.first
      close_date = date.parts.second

      unless date.uncertain? || (open_date && close_date)
        # let csl-ruby handle it normally, it's a single date or no date at all, not a range!
        return nil
      end

      # We're just gonna do years, if they're both the same year, just call it a year.
      formatted_date = if close_date.nil? || open_date.year == close_date.year
        open_date.year.to_s
      else
        # that's an en-dash not a hyphen.
        "#{open_date.year}–#{close_date.year}"
      end

      if date.uncertain?
        formatted_date ="circa #{formatted_date}"
      end

      return formatted_date
    end

    # adds formatted date range as a literal if present.
    def issued_date_csl
      return nil unless date

      date_csl = date.to_citeproc

      if edge_case_date_literals?
        literal = formatted_date_literal
        date_csl["literal"] = literal if literal
      end

      return date_csl
    end

    def edge_case_date_literals?
      @edge_case_date_literals
    end

    delegate :authors, :publisher, :publisher_place, :date, :container_title,
      :medium, :archive_location, :archive, :archive_place, :title, :csl_id,
      :abstract, :csl_type, :url, :authors_formatted,
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
        issued: issued_date_csl,
        publisher: publisher,
        "publisher-place": publisher_place,
        medium: medium,
        "URL": url,
        archive: archive,
        'archive-place': archive_place,
        archive_location: archive_location,
        "container-title": container_title
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
      attr_reader :work, :collection, :parent_work
      def initialize(work, collection: nil, parent_work: nil)
        @work = work
        @collection = collection
        @parent_work = parent_work
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
        genre_string = work.genre_string || []

        if genre_string.include?('Manuscripts')
          return "manuscript"
        elsif (genre_string & ['Rare books', 'Sample books']).present?
          if container_title.present?
            return "chapter"
          else
            return "book"
          end
        elsif genre_string.include?('Documents') && title =~ /report/i
          return "report"
        elsif  division?("Archives")
          # if it's not one of above known to use archival metadata, and it's in
          # Archives, insist on Manuscript.
          return "manuscript"
        elsif (genre_string & %w{Paintings}).present?
          return "graphic"
        elsif genre_string.include?('Slides')
          return "graphic"
        elsif genre_string.include?('Encyclopedias and dictionaries')
          if container_title.present?
            return "chapter"
          else
            return "book"
          end
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
          first_present_field_values(%w{creator_of_work author artist photographer engraver interviewer}).collect do |str_name|
            parse_name(str_name)
          end
        end
      end

      # An array of formatted `lastname, first` like typical for RIS AU field and other
      # non-structured single-string author uses.
      #
      # Code extracted from:
      # https://github.com/inukshuk/citeproc/blob/52fb498b59e4d1c30eb9a44d18bb7a5e10cfaae8/lib/citeproc/names.rb#L314-L337
      def authors_formatted
        memoize(:authors_formatted) do
          authors.collect do |citeproc_name|
            if citeproc_name.literal.present?
              citeproc_name.literal
            elsif !citeproc_name.demote_particle?
              [
                [citeproc_name.particle, citeproc_name.family].compact.join(' '),
                [citeproc_name.initials, citeproc_name.dropping_particle].compact.join(' '),
                citeproc_name.suffix
              ].compact.join(citeproc_name.comma)
            else
              [
                citeproc_name.family,
                [citeproc_name.initials, citeproc_name.dropping_particle, citeproc_name.particle].compact.join(' '),
                citeproc_name.suffix
              ].compact.join(citeproc_name.comma)
            end
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
          if work.date_of_work_models.present?
            cite_proc_dates = work.date_of_work_models.collect { |d| local_date_to_citeproc_date(d) }.compact

            min_date_part = cite_proc_dates.collect(&:date_parts).flatten.min
            max_date_part = cite_proc_dates.collect(&:date_parts).flatten.max

            if min_date_part.nil? && max_date_part.nil?
              return nil
            end

            date = if min_date_part == max_date_part
              ::CiteProc::Date.new(min_date_part.to_a.compact)
            else
              ::CiteProc::Date.new([min_date_part.to_a.compact, max_date_part.to_a.compact])
            end

            if cite_proc_dates.any?(&:uncertain?)
              date.uncertain!
            end

            return date
          end
        end
      end

      def medium
        memoize(:medium) do
          if work.medium.present?
            work.medium.collect(&:downcase).join(", ")
          else
            nil
          end
        end
      end

      def url
        "#{CHF::Env.lookup(:app_url_base)}/works/#{work.id}"
      end

      def container_title
        memoize(:container_title) do
          if work.source.present?
            work.source.first
          elsif parent_work && parent_work.title.present?
            parent_work.title.first
          end
        end
      end

      def shelfmark
        memoize(:shelfmark) do
          if work.physical_container_structured_str.present?
            CHF::Utils::ParseFields.parse_physical_container(work.physical_container_structured_str)["s"]
          end
        end
      end

      # We decided NOT to include series/subseries in citation, just collection and physical lcoation
      def archive_location
        #memoize(:archive_location) do
          if division?("Archives")
            parts = []

            if collection && collection.title.present?
              parts << collection.title.first
            end

            parts << work.physical_container if work.physical_container.present?
            parts.collect(&:presence).compact.join(', ')
          elsif division?("Library") && self.shelfmark
            self.shelfmark
          end
        #end
      end

      def archive_place
        if division?("Archives", "Museum") || shelfmark
          "Philadelphia"
        end
      end

      def archive
        if division?("Archives", "Museum") || shelfmark
          "Science History Institute"
        end
      end

      protected

      # we use our own :memoize instead of `||=` so it can memoize nil
      def memoize(key)
        key = key.to_sym
        @__memoized ||= {}
        unless @__memoized.has_key?(key)
          @__memoized[key] = yield
        end
        @__memoized[key]
      end

      def division?(*divisions)
        work.division && (work.division & divisions).length > 0
      end


      # _single_ local date object to a citeproc date
      def local_date_to_citeproc_date(date)
        # we consider 'before' or 'after' not enough info for a date for citation at present,
        # haven't figured out how to interact with CSL to represent these, may be possible.
        if ([date.start_qualifier, date.finish_qualifier].compact & ['before', 'after']).count > 0
          return nil
        end

        if date.start_qualifier == "decade"
          open_year = date.start.to_i / 10 * 10 # cut off year
          close_year = open_year + 9
          return CiteProc::Date.new([[open_year], [close_year]])
        end


        if date.start_qualifier == "century"
          open_year = date.start.to_i / 100 * 100 # cut off tens and units
          close_year = open_year + 99
          return CiteProc::Date.new([[open_year], [close_year]])
        end

        # year, month, date
        start_part = date.start.presence && date.start.scan(/\d+/).slice(0..2)
        finish_part = date.finish.presence && date.finish.scan(/\d+/).slice(0..2)

        args = []
        args << start_part if start_part
        args << finish_part if finish_part
        return nil if args.empty?

        CiteProc::Date.new(args).tap do |citeproc_date|
          if date.start_qualifier == "circa" || date.finish_qualifier == "circa"
            citeproc_date.uncertain!
          end
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
          str.split("--").reverse.join(", ").sub(" (State)", '')
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
        date_suffix = /,? (active |approximately )?\d\d\d\d\??-((approximately )?\d\d\d\d\??)?|,? -\d\d\d\d\??\Z/

        # remove 'inc'
        str.sub!(/, inc\. */, '')

        parsed_name = nil

        if str =~ date_suffix
          # looks like a personal name with birth/death dates, remove em and parse
          str.sub!(date_suffix, '')
          parsed_name = Namae::Name.parse(str)
          parsed_name = nil if parsed_name.empty?
        end

        if parsed_name.nil? && str =~ /\A *[A-Z][^,()]*(, *[A-Z][^,()]*)+ *\Z/
          # looks like a personal name in inverted form
          parsed_name = Namae::Name.parse(str)
          parsed_name = nil if parsed_name.empty?
        end

        if parsed_name
          CiteProc::Name.new(parsed_name)
        else
          # a corporate name, or something we didn't succesfully parse
          CiteProc::Name.new(literal: str)
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
        date_of_photo = Date.strptime(work.date_uploaded, '%m/%d/%Y')
        # we only give it the year, we don't really trust the other stuff anyway.
        date_of_photo ? CiteProc::Date.new([date_of_photo.year]) : nil
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

    class TreatAsOralHistory < StandardTreatment
      def title
        return work.title if work.interviewee.nil? || work.interviewer.nil?
        place = work.place_of_interview.nil? ? "" : "in #{normalize_place(work.place_of_interview.first)}"
        time = original_date.nil? ? "" : "on #{original_date.strftime("%B %-d, %Y")}"
        "#{parse_name(work.interviewee.first).format}, interviewed by #{parse_name(work.interviewer.first).format} #{place} #{time}"
      end

      def csl_type
        "interview"
      end

      def authors
        [] # Having no "authors" is regrettable, but such is the consequence
        # of having ruby-csl treat this as an "interview".
      end

      def medium
        nil
      end

      def publisher_place
        'Philadelphia'
      end

      def publisher
        'Science History Institute'.freeze
      end

      # no date in CSL, we're embedding it in title instead
      def date
        nil
      end

      # we don't want to be used in CSL, but we want to pull it out to use in title
      def original_date
        return nil if work.date_of_work.nil? || work.date_of_work.length == 0
        begin
          date_recorded = Date.strptime(work.date_of_work.first, '%Y-%m-%d')
        rescue ArgumentError
          return nil
        end
        date_recorded ? CiteProc::Date.new(date_recorded) : nil
      end

      def archive_location
        if work.identifier && interview_id_str = work.identifier.find { |id| id.start_with? /interview-/}
          interview_number = interview_id_str.sub(/\Ainterview-/, '')
          "Oral History Transcript #{interview_number}" if interview_number.present?
        end
      end
    end


  end
end
