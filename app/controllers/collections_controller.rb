class CollectionsController < ApplicationController
  include CurationConcerns::CollectionsControllerBehavior
  include Sufia::CollectionsControllerBehavior

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
