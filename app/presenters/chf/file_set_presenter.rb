module CHF
  # Add some things we can use for our custom UI
  class FileSetPresenter < Sufia::FileSetPresenter

    delegate :original_file_id, to: :solr_document

    # Consistent API with GenericWorkShowPresenter, on show pages we often
    # only show permissoin badge if not open access.
    def needs_permission_badge?
      solr_document.visibility != Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    def representative_file_set_id
      id
    end

    def representative_file_id
      # if it's not in solr, try to get it from fedora
      if original_file_id
        return original_file_id
      else
        Rails.logger.error "ERROR: Could not find FileSet #{id} original_file_id in Solr. You may need to reindex."

        # it's really too slow to fetch from fedora, give up if we can't get it in solr.
        return nil

        #original_file_set = FileSet.find(id) if id
        #return original_file_set && original_file_set.original_file && original_file_set.original_file.id
      end
    end

    def representative_checksum
      Array(solr_document[Solrizer.solr_name("original_file_checksum")]).first
    end

    def representative_content_type
      Array(solr_document[Solrizer.solr_name("original_file_content_type")]).first
    end

    def representative_page_count
      Array(solr_document[Solrizer.solr_name("original_file_page_count", type: :integer)]).first
    end

    def representative_height
      height
    end

    def representative_width
      width
    end

  end
end
