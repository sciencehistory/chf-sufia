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
        subject: ["Portraits, Group", "Women in science", "Employees"]
      },
      science_on_stamps: {
        subject: ["Science on postage stamps"]
      },
      instruments_and_innovation: {
        genre: ["Scientific apparatus and instrument"],
        subject: ["Artillery", "Machinery", "Chemical apparatus",
                  "Laboratories--Equipment and supplies",
                  "Chemical laboratories--Equipment and supplies",
                  "Glassware"]
      },
      alchemy: {
        subject: ["Alchemy", "Alchemists"]
      },
      scientific_education: {
        genre: ["Chemistry sets", "Molecular models"],
        subject: ["Science--study and teaching"]
      },
      health_and_medicine: {
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

    attr_accessor :category_key

    def initialize(category_key)
      unless self.class.has_key?(category_key)
        raise ArgumentError, "No such category key: #{category_key}"
      end
      @category_key = category_key.to_sym
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
