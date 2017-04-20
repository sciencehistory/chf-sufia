class SearchBuilder
  # A search builder module to restrict to a certain SyntheticCollection.
  #
  # This module doesn't do anything just by being included, it needs one
  # of synthetic_category_param or synthetic_category_force to be set -- on
  # either the class or the instance.
  #
  # synthetic_category_param sets a key to take from the app query params
  # to map to a collection. You might set it on a class, with:
  #
  #      SearchBuilder.synthetic_category_param = :category
  #
  # synthetic_category_force forces to a specific category, you might
  # set it on a particular search_builder instance:
  #
  #      some_search_builder.tap { |sb| sb.synthetic_category_force = :portraits_and_people }.search(...)
  #
  # Now when you do things with that search builder, it's locked to :portraits_and_people
  #
  #     synthetic_category_param : set to a symbol, and this will be taken
  #       from app params to identify a collection to limit to.  If a string
  #        not matching a category is provided, will limit to 0 results, beware!
  #     synthetic_category_force: symbol of synthetic collection key,
  #       will just force limiting to there.
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
      elsif synthetic_category_param.present? && blacklight_params[synthetic_category_param].present?
        # trying to use param mapping for a category that doesn't exist, let's give you zero
        # results!
        solr_params[:fq] ||= []
        solr_params[:fq] << "-*:*"
      end

    end

  end
end
