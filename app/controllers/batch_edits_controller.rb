class BatchEditsController < ApplicationController
  include Hydra::BatchEditBehavior
  include GenericFileHelper
  include Sufia::BatchEditsControllerBehavior

  def terms
    BatchEditForm.terms
  end

  def generic_file_params
    file_params = params[:generic_file] || ActionController::Parameters.new()
    BatchEditForm.model_attributes(file_params)
  end

end
