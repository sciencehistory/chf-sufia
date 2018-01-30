# Generated via
#  `rails generate curation_concerns:work GenericWork`

module CurationConcerns
  class GenericWorksController < ApplicationController
    include CurationConcerns::CurationConcernController
    # Adds Sufia behaviors to the controller.
    include Sufia::WorksControllerBehavior

    self.curation_concern_type = GenericWork
    self.show_presenter = CurationConcerns::GenericWorkShowPresenter

    # our custom local layout intended for public show page, but does
    # not seem to mess up admin pages also in this controller.
    layout "chf"

    # returns JSON for the viewer, an array of hashes, one for each image
    # included in this work to be viewed.
    # Note we needed to make this action auth right with a custom line in
    # in our ability.rb class.
    def viewer_images_info
      render json: helpers.viewer_images_info(presenter)
    end

    protected

    # override from curation_concerns to add additional response formats to #show
    def additional_response_formats(wants)
      wants.ris do
        @curation_concern = _curation_concern_type.find(params[:id]) unless curation_concern
        render body: CHF::RisSerializer.new(@curation_concern).serialize
      end
    end

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

    # Adds the 'My Works' breadcrumb; we only want this for logged-in users
    # overrides https://github.com/samvera/sufia/blob/v7.3.1/app/controllers/concerns/sufia/works_controller_behavior.rb#L93
    def add_breadcrumb_for_controller
      super if current_ability.current_user.logged_in?
    end

    # overriding presenter to pass in view_context
    def presenter(*args)
      super.tap do |pres|
        pres.view_context = view_context if pres.respond_to?(:view_context=)
      end
    end

  end
end
