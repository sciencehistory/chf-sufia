class BatchEditsController < ApplicationController
  include Hydra::BatchEditBehavior
  include FileSetHelper
  include Sufia::BatchEditsControllerBehavior

  def form_class
    BatchEditForm
  end

  # nearly straight-up copy of sufia's method
  def update
    case params["update_type"]
    when "update"
      update_works
    when "delete_all"
      destroy_batch
    end
  end

  # the bulk of this is from hydra-batch-edit, with jobs processing added in.
  # I tried to add the jobs by overriding update_document, which would have
  # been a smaller change, but that required saving the object twice, since the
  # object needs to be saved before it's passed to the jobs.
  def update_works
    batch.each do |doc_id|
      obj = ActiveFedora::Base.find(doc_id, :cast=>true)
      previous_visibility = obj.visibility
      update_document(obj)
      obj.save
      VisibilityCopyJob.perform_later(obj) unless previous_visibility == obj.visibility
      InheritPermissionsJob.perform_later(obj) if work_params.fetch(:permissions_attributes, nil)
    end
    flash[:notice] = "Batch update complete"
    after_update
  end
end
