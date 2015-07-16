class GenericFilesController < ApplicationController
  include Sufia::Controller
  include Sufia::FilesControllerBehavior

  self.presenter_class = GenericFilePresenter
  self.edit_form_class = GenericFileEditForm

  # TODO This is a temporary override of sufia to fix #101
  #      This can be removed once sufia has a solution and we upgrade or
  #      batches are no longer used when sufia migrates to PCDM
  # routed to /files/new
  def new
    @batch_id  = Batch.create.id
  end
end
