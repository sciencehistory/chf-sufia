module CHF
  class CitableAttributes
    # Renders a citation in HTML from a work_presenter using CitableAttributes, and ruby CSL
    #
    # Assumes the chicago-note-bibliography CSL style and en-US locale -- lazy loads them
    # both globally because they are slow to load.
    #
    # Does return an html_safe string
    #
    # @example
    #
    #     CHF::CitableAttributes::Renderer.new(citable_attributes_obj).render_html
    #     CHF::CitableAttributes::Renderer.from_work_presenter(work_presenter).render_html
    class Renderer
      # reuse this style cause it's expensive to load. It appears to be concurrency-safe.
      def self.csl_chicago_style
        @csl_chicago_style ||= ::CSL::Style.load("chicago-note-bibliography")
      end

      # similar to csl_chicago_style
      def self.csl_en_us_locale
        @csl_en_us_locale ||= ::CSL::Locale.load("en-US")
      end

      attr_reader :citable_attributes

      def initialize(citable_attributes)
        raise ArgumentError.new("argument must be CHF::CitableAttributes") unless citable_attributes.kind_of?(CHF::CitableAttributes)
        @citable_attributes = citable_attributes
      end

      def self.from_work_presenter(work_presenter)
        self.new(CHF::CitableAttributes.new(work_presenter))
      end

      # returns an html_safe string
      def render_html
        csl_data = citable_attributes.as_csl_json.stringify_keys

        citation_item = CiteProc::CitationItem.new(id: csl_data["id"] || "id") do |c|
          c.data = CiteProc::Item.new(csl_data)
        end

        renderer = CiteProc::Ruby::Renderer.new :format => CiteProc::Ruby::Formats::Html.new,
          :locale => self.class.csl_en_us_locale

        renderer.render(citation_item, self.class.csl_chicago_style.bibliography).html_safe
      end
    end
  end
end
