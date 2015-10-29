class GenericFilesController < ApplicationController
  include Sufia::Controller
  include Sufia::FilesControllerBehavior

  self.presenter_class = GenericFilePresenter
  self.edit_form_class = GenericFileEditForm

end
