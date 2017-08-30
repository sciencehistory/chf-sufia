class SearchBuilder
  module PublicDomainFilter
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain += [:public_domain_filter]
    end

    def public_domain_filter(solr_params)
      # look for the checkbox; transform it into a facet param
      if blacklight_params.fetch("filter_public_domain", 0).to_i > 0
        solr_params[:fq] ||= []
        public_domain_filter = "{!term f=rights_sim}http://creativecommons.org/publicdomain/mark/1.0/"
        solr_params[:fq] << public_domain_filter
      end
    end

  end
end
