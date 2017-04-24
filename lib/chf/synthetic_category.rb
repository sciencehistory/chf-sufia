module CHF
  # Our "Synthetic categories" are lists of works put together
  # based on other already existing metadata. For instance, any work
  # with a genre "Portraits" OR a subject "Portraits, Group" OR a
  # subject "Women in science" might be considered part of the
  # synthetic category "Portraits & People"
  #
  # At present, we do NOT index these categories, rather we just
  # dynamically fetch them by doing queries on a real index.
  #
  # There isn't right now API to determine what synthetic categories an
  # individual work belongs to (rather than just being in the results of a
  # fetch for the category), but there could be.
  class SyntheticCategory
    GENRE_FACET_SOLR_FIELD = ActiveFedora.index_field_mapper.solr_name("genre_string", :facetable)
    SUBJECT_FACET_SOLR_FIELD = ActiveFedora.index_field_mapper.solr_name("subject", :facetable)

    class_attribute :definitions, instance_writer: false
    # Different collections keyed by colleciton symbol, value is a hash
    # listing genres and subjects. Thing is member of synthetic collection
    # if it has _any_ of the listed genres or _any_ of the listed subjects.
    self.definitions = {
      portraits_and_people: {
        genre: ["Portraits"],
        subject: ["Portraits, Group", "Women in science", "Employees"],
        title: "Portraits & People",
        description: "A selection of our digitized material on interesting people in the history of science, CHF has some great ones."
      },
      science_on_stamps: {
        subject: ["Science on postage stamps"],
        description: "CHF has some great postage stamps from around the world on science topics. Here are some we've digitized."
      },
      instruments_and_innovation: {
        title: "Instruments & Innovation",
        genre: ["Scientific apparatus and instrument"],
        subject: ["Artillery", "Machinery", "Chemical apparatus",
                  "Laboratories--Equipment and supplies",
                  "Chemical laboratories--Equipment and supplies",
                  "Glassware"],
        description: "CHF's collections include a focus on instruments and innovation in scientific tools, here are some interesting materials we've digitized."
      },
      alchemy: {
        subject: ["Alchemy", "Alchemists"],
        description: "Alchemy is an interesting part of the history of chemistry."
      },
      scientific_education: {
        genre: ["Chemistry sets", "Molecular models"],
        subject: ["Science--study and teaching"],
        description: "Chemistry sets and more."
      },
      health_and_medicine: {
        title: "Health & Medicine",
        description: "Selected digitized items from the CHF collections on topics of health and medicine.",
        subject: [
          "Toxicology",
          "Gases, Asphyxiating and poisonous--Toxicology",
          "Biology",
          "Biochemistry",
          "Hearing aids",
          "Drugs",
          "Electronics in space medicine",
          "Infants--Health and hygiene",
          "Medical botanists",
          "Medical education",
          "Medical electronics",
          "Medical electronics--Equipment and supplies",
          "Medical instruments and apparatus",
          "Medical laboratories--Equipment and supplies",
          "Medical laboratories--Equipment and supplies--Standards",
          "Medical laboratory equipment industry",
          "Medical physics",
          "Medical sciences",
          "Medical students",
          "Medical technologists",
          "Medicine",
          "Medicine bottles",
          "Newborn infants--Medical care",
          "Public health",
          "Space medicine",
          "Women in medicine"
        ]
      }
    }

    def self.has_key?(category_key)
      return unless category_key.present?
      definitions.has_key?(category_key.to_sym)
    end

    def self.keys
      definitions.keys
    end

    def self.all
      keys.collect { |key| self.new(key) }
    end

    # Our symbol keys use underscores eg `:portraits_and_people`, but it's nicer
    # to have hyphens in the URL eg `/portraits-and-people`. Look up a SyntheticCategory
    # object from slug in URL.
    def self.from_slug(slug)
      if slug.blank?
        nil
      elsif has_key?(slug)
        self.new(slug)
      elsif has_key?(slug.underscore)
        self.new(slug.underscore)
      else
        nil
      end
    end


    attr_accessor :category_key

    # Our symbol keys use underscores eg `:portraits_and_people`, but it's nicer
    # to have hyphens in the URL eg `/portraits-and-people`. Translate to a slug
    # suitable for use in a URL, see also .from_slug.
    def slug
      category_key.to_s.dasherize
    end

    def initialize(category_key)
      unless self.class.has_key?(category_key)
        raise ArgumentError, "No such category key: #{category_key}"
      end
      @category_key = category_key.to_sym
    end

    def title
      # This could use i18n, but this simpler seems good enough for now,
      # We don't even use locales anyway.
      if definition.has_key?(:title)
        definition[:title]
      else
        category_key.to_s.humanize.titlecase
      end
    end

    def description
      # This could use i18n, but this simpler seems good enough for now,
      # We don't even use locales anyway.
      if definition.has_key?(:description_html)
        definition[:description_html].html_safe
      elsif definition.has_key?(:description)
        definition[:description]
      else
        nil
      end
    end

    def solr_fq
      fq_elements = []

      if definition[:subject].present?
        fq_elements << "#{SUBJECT_FACET_SOLR_FIELD}:(#{fq_or_statement definition[:subject]})"
      end
      if definition[:genre].present?
        fq_elements << "#{GENRE_FACET_SOLR_FIELD}:(#{fq_or_statement definition[:genre]})"
      end

      fq_elements.join(" OR ")
    end

    protected

    def definition
      definitions[category_key]
    end

    def fq_or_statement(values)
      values.
        collect { |s| s.gsub '"', '\"'}. # escape double quotes
        collect { |s| %Q{"#{s}"} }. # wrap in quotes
        join(" OR ")
    end


  end
end
