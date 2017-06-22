module CHF
  # Add some things we can use for our custom UI
  class FileSetPresenter < Sufia::FileSetPresenter
    # Consistent API with GenericWorkShowPresenter, on show pages we often
    # only show permissoin badge if not open access.
    def needs_permission_badge?
      solr_document.visibility != Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
  end
end
