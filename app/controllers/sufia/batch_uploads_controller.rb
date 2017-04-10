class Sufia::BatchUploadsController < ApplicationController
  include Sufia::BatchUploadsControllerBehavior

  self.work_form_service = ::BatchUploadFormService
  self.curation_concern_type = work_form_service.form_class.model_class

end
