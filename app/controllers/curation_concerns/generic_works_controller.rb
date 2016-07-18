# Generated via
#  `rails generate curation_concerns:work GenericWork`

module CurationConcerns
  class GenericWorksController < ApplicationController
    include CurationConcerns::CurationConcernController
    # Adds Sufia behaviors to the controller.
    include Sufia::WorksControllerBehavior

    self.curation_concern_type = GenericWork
    self.show_presenter = CurationConcerns::GenericWorkShowPresenter

    # not sure whether I need these.. (from sufia 6)
    #self.presenter_class = GenericFilePresenter
    #self.edit_form_class = GenericFileEditForm
  end
end
