class CollectionsController < ApplicationController
  include CurationConcerns::CollectionsControllerBehavior
  include Sufia::CollectionsControllerBehavior

  def form_class
    CollectionEditForm
  end

end
