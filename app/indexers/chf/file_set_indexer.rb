module CHF
  class FileSetIndexer < CurationConcerns::FileSetIndexer
    def generate_solr_document
      super.tap do |doc|
        if object.original_file
          doc[ActiveFedora.index_field_mapper.solr_name('original_file_id')] = object.original_file.id
          doc[ActiveFedora.index_field_mapper.solr_name('original_file_checksum')] = object.original_file.checksum.value
        end
      end
    end
  end
end
