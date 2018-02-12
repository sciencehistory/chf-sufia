# controller JUST for 'show collection' action, we make it inherit
# from CatalogController so it's easier to make it support full search with
# facets etc. But with some behavior copied from CurationConcerns::CollectionControllerBehavior
#

class CollectionsShowController < CatalogController
  include Sufia::Breadcrumbs

  layout 'chf'

  def show
    build_breadcrumbs

    presenter # load Collection presenter
    (@response, _deprecated_document_list) = search_results(params) # from blacklight Catalog#index
    @parent_presenter_lookup = parent_lookup_hash(@response.documents) # to look up parents to show, in one query
  end

  # Override from Blacklight catalog.rb to get facet id out of :facet_id,
  # so :id can continue being our parent collection id.
  # displays values and pagination links for a single facet field
  def facet
    @facet = blacklight_config.facet_fields[params[:facet_id]]
    @response = get_facet_field_response(@facet.key, params)
    @display_facet = @response.aggregations[@facet.key]
    @pagination = facet_paginator(@facet, @display_facet)
    respond_to do |format|
      # Draw the facet selector for users who have javascript disabled:
      format.html
      format.json
      # Draw the partial for the "more" facet modal window:
      format.js { render :layout => false }
    end
  end

  # catalog controller action method we don't want to expose
  protected :index

  protected

  def search_builder_class
    # limit just to docs in collection. Sufia overrides this so you can no longer set
    # with blacklight_config, gah.
    CurationConcerns::CollectionMemberSearchBuilder
  end

  # Get controller to find templates in CollecitonsController too,
  # so we can re-use more of the sufia stuff for collection. Messy messy.
  def self.local_prefixes
    @local_prefixes ||= super.concat ['collections']
  end

  def member_docs
    @member_docs ||= @response.documents
  end
  helper_method :member_docs

  def presenter
    @presenter ||= begin
      # Query Solr for the collection.
      response = repository.search(single_item_search_builder.query)
      curation_concern = response.documents.first
      raise CanCan::AccessDenied unless curation_concern
      CHF::CollectionShowPresenter.new(curation_concern, current_ability)
    end
  end
  helper_method :presenter

  def single_item_search_builder
    CurationConcerns::SingleCollectionSearchBuilder.new(self).with(params.slice(:id))
  end

  def add_breadcrumb_for_controller
    add_breadcrumb I18n.t('sufia.dashboard.my.collections'), sufia.dashboard_collections_path
  end

  def add_breadcrumb_for_action
    case action_name
    when 'show'.freeze
      add_breadcrumb presenter.to_s, main_app.polymorphic_path(presenter)
    end
  end

  # Have to override this helper method from Blacklight to tell it, no, keep the
  # search HERE in this controller, don't go over to #index action. Ergh.
  # https://github.com/projectblacklight/blacklight/blob/v6.7.2/app/controllers/concerns/blacklight/controller.rb#L71-L74
  def search_action_url options = {}
     url_for(options.except(:controller, :action))
  end
  helper_method :search_action_url

  # override to put the facet id in :facet_id instead of :id, so we can keep
  # :id for our parent collection id.
  def search_facet_url options = {}
    if options.has_key?(:id)
      options[:facet_id] = options.delete(:id)
    end
    super(options)
  end


end


