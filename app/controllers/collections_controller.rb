class CollectionsController < ApplicationController
  include CurationConcerns::CollectionsControllerBehavior
  include Sufia::CollectionsControllerBehavior

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
end
