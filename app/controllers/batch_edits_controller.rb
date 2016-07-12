class BatchEditsController < ApplicationController
  include Hydra::BatchEditBehavior
  include FileSetHelper
  include Sufia::BatchEditsControllerBehavior

  def terms
    BatchEditForm.terms - [
        :division,
        :physical_container,
        :rights_holder,
        :file_creator,
        :admin_note,
        :date_of_work,
        :inscription,
        :additional_credit,
    ]
  end

  def generic_file_params
    file_params = params[:generic_file] || ActionController::Parameters.new()
    BatchEditForm.model_attributes(file_params)
  end

end
