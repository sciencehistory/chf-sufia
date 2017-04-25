# Generated via
#  `rails generate curation_concerns:work GenericWork`

module CurationConcerns
  class GenericWorksController < ApplicationController
    include CurationConcerns::CurationConcernController
    # Adds Sufia behaviors to the controller.
    include Sufia::WorksControllerBehavior

    self.curation_concern_type = GenericWork
    self.show_presenter = CurationConcerns::GenericWorkShowPresenter


    protected

    # Pretty hacky way to override the t() I18n method when called from template:
    # https://github.com/projecthydra/sufia/blob/8bb451451a492e443687f8c5aff4882cac56a131/app/views/curation_concerns/base/_relationships_parent_row.html.erb
    # ...so  we can catch what would have been "In Generic work" and replace with
    # "Part of", while still calling super for everything else, to try and
    # avoid breaking anything else.
    #
    # The way this is set up upstream, I honestly couldn't figure out
    # a better way to intervene without higher chance of forwards-compat
    # problems on upgrades. It could not be overridden just in i18n to do
    # what we want.
    module HelperOverride
      def t(key, interpolations = {})
        if key == ".label" && interpolations[:type] == "Generic work"
          "Part of:"
        else
          super
        end
      end
    end
    helper HelperOverride

  end
end
