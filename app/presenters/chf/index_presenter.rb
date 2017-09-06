module Chf
  # Unlike the show presenters based on sufia code, the index presenter
  # is based on Blacklight code. It is used on the search results screen,
  # and is used for ALL models, the Blacklight architecture doesn't choose
  # different presenters for different models.
  #
  # We supply some custom methods to make it appear more like a sufia
  # presenter, to allow some code sharing. Yes, this is a dangerous game,
  # hard to know if we have API-compatibility with the other one, but this
  # was the lesser evil.
  class IndexPresenter < Blacklight::IndexPresenter
    delegate :description, to: :solr_document

    # Make it look more like a sufia presenter
    def current_ability
      view_context.try(:current_ability)
    end

    # sufia presenters call it this, so we provice this to make code-sharing
    # easier.
    def solr_document
      document
    end

    # More like sufia presenter
    def request
      view_context.request
    end

    # handy
    def has_values_for?(field_name)
      solr_document[field_name].present?
    end

    # "representative_" methods are copied from GenericWorkShowPresenter, so
    # we can use this presenter the same way for displaying representative images.
    # Possible improvement: DRY this code between here and there.
    def representative_id
      solr_document.representative_id
    end

    def representative_file_id
      Array.wrap(solr_document[ActiveFedora.index_field_mapper.solr_name('representative_original_file_id')]).first
    end

    def representative_checksum
      Array.wrap(solr_document[ActiveFedora.index_field_mapper.solr_name('representative_checksum')]).first
    end

    def representative_height
      Array.wrap(solr_document[ActiveFedora.index_field_mapper.solr_name('representative_height', type: :integer)]).first
    end

    def representative_width
      Array.wrap(solr_document[ActiveFedora.index_field_mapper.solr_name('representative_width', type: :integer)]).first
    end

    # also to make it like a show presenter
    def thumbnail_path
      solr_document.thumbnail_path
    end

  end
end
