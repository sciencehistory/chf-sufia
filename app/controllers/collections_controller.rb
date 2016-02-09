class CollectionsController < ApplicationController
  include Sufia::CollectionsControllerBehavior

  def form_class
    CollectionEditForm
  end

end
