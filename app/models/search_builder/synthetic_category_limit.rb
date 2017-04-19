class SearchBuilder
  # A search builder module to restrict to a certain SyntheticCollection.
  # Won't do _anything_ just by being in the chain -- sets class_attributes
  # on the SearchBuilder that can be used to turn it 'on', either on the class
  # or even on an instance.
  #
  #.    synthetic_category_param : set to a string, and this will be taken
  #.      from app params to identify a collection to limit to.  If unknown,
  #.      will do nothing. (Should limit to 0 rows instead?)
  #.    synthetic_category_force: symbol of synthetic collection key,
  #.      will just force limiting to there.
  module SyntheticCategoryLimit
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain += [:synthetic_collection_limit]
      class_attribute :synthetic_category_param
      class_attribute :synthetic_category_force
    end


    def synthetic_collection_limit(solr_params)
      synthetic_category = if synthetic_category_force.present?
        CHF::SyntheticCategory.new(synthetic_category_force)
      elsif synthetic_category_param.present? && CHF::SyntheticCategory.has_key?(blacklight_params[synthetic_category_param])
        CHF::SyntheticCategory.new(blacklight_params[synthetic_category_param])
      end

      if synthetic_category
        solr_params[:fq] ||= []
        solr_params[:fq] << synthetic_category.solr_fq
      elsif synthetic_category_param.present?
        # trying to use param mapping for a category that doesn't exist, let's give you zero
        # results!
        solr_params[:fq] ||= []
        solr_params[:fq] << "-*:*"
      end

    end

  end
end
