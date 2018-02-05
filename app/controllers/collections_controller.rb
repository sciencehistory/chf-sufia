class CollectionsController < ApplicationController
  include CurationConcerns::CollectionsControllerBehavior
  include Sufia::CollectionsControllerBehavior

  include ParentLookup

  self.presenter_class = CHF::CollectionShowPresenter

  layout 'chf'

  # Override to use the sort_widget from catalog, not the sufia override. What are we missing
  # from the sufia override? Not sure! But it didn't CSS style correctly.
  view_type_action = blacklight_config.index.collection_actions["view_type_group"]
  view_type_action.partial = "catalog/view_type_group" if view_type_action

  def form_class
    CollectionEditForm
  end

  def index
    documents = super
    @presenters = documents.
      map { |document| presenter_class.new(document, current_ability) }.
      sort! { |x,y| x.title.first <=> y.title.first }
  end

  def show
    super
    @parent_presenter_lookup = parent_lookup_hash(@member_docs)
  end

  protected

  # Have to override method from curation_concerns to ignore facets when trying
  # to fetch collection. gah.
  # https://github.com/samvera/curation_concerns/blob/v1.7.8/app/controllers/concerns/curation_concerns/collections_controller_behavior.rb?utf8=%E2%9C%93#L177-L192
  def single_item_search_builder
    single_item_search_builder_class.new(self).with(params.except(:q, :page, :f))
  end

  # Have to override this helper method from Blacklight to tell it, no, keep the
  # search HERE in this controller, don't go over to CatalogController. Ergh.
  # https://github.com/projectblacklight/blacklight/blob/v6.7.2/app/controllers/concerns/blacklight/controller.rb#L71-L74
  def search_action_url options = {}
    url_for(options.except(:controller, :action, :q))
  end
  helper_method :search_action_url

end
