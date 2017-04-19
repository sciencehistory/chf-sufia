# Only a 'show' action
#
# Based roughly off of Sufia/CurationConcerns CollectionController#show
# TODO link to CollectionControllerBehavior in both
class SyntheticCategoryController < ApplicationController
    # include Blacklight::AccessControls::Catalog
    include Blacklight::Base

    # ??
    copy_blacklight_config_from(::CatalogController)

    def show
      unless synthetic_category
        raise ActionController::RoutingError.new("No SyntheticCategory matches `#{params[:id]}`")
      end
      set_response # trigger setting of @response, which I think some partials need.
    end


    protected

    # Get controller to find templates in CollectionController too,
    # so we can re-use more of the sufia stuff for collection. Messy messy.
    def self.local_prefixes
      @local_prefixes ||= super.push('collections')
    end

    def synthetic_category
      @synthetic_cateogry = if CHF::SyntheticCategory.has_key?(params[:id])
        CHF::SyntheticCategory.new(params[:id])
      else
        nil
      end
    end
    helper_method :synthetic_category

    def search_builder
      @search_builder ||= SearchBuilder.new(self).tap { |sb| sb.synthetic_category_force = params[:id] }
    end

    def set_response
      @response ||= repository.search( search_builder.with(params.merge(q: params[:cq])).query )
    end

    def results
      set_response
      @results ||= @response.documents
    end
    helper_method :results

end
