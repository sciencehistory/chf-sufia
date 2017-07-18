module CHF
  # Looks up info from config/authorities/license.yml, which is used by
  # QuestioningAuthority.  The QA logic for accessing it had some serious
  # performance problems being used as much as it was -- not caching YML, architected
  # in a way that makes it hard to fix to cache YML. So we write our own simple cover.
  #
  #     RightsTerms.category_for("http://rightsstatements.org/vocab/InC-OW-EU/1.0/")
  #     RightsTerms.short_label_html_for("http://rightsstatements.org/vocab/InC-OW-EU/1.0/")
  #     RightsTerms.metadata_for("http://rightsstatements.org/vocab/InC-OW-EU/1.0/")
  class RightsTerms

    def initialize(yaml_file_path = Rails.root.join("config/authorities/licenses.yml"))
      @yaml_file_path = yaml_file_path
    end

    def metadata_for(id)
      terms_by_id[id]
    end

    def category_for(id)
      metadata_for(id).try { |h| h["category"] }
    end

    def short_label_html_for(id)
      metadata_for(id).try { |h| h["short_label_html"] }
    end

    def self.global
      @global ||= self.new
    end

    class << self
      delegate :metadata_for, :category_for, :short_label_html_for, to: :global
    end

    private

    def terms_by_id
      @terms_by_id ||= YAML.load(File.read(@yaml_file_path))["terms"].collect do |hash|
                        [hash["id"], hash]
                      end.to_h
    end

  end
end
