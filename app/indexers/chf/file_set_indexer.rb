module CHF
  class FileSetIndexer < CurationConcerns::FileSetIndexer
    def generate_solr_document
      super.tap do |doc|
        if object.original_file
          doc[ActiveFedora.index_field_mapper.solr_name('original_file_id')] = object.original_file.id
          doc[ActiveFedora.index_field_mapper.solr_name('original_file_checksum')] = object.original_file.checksum.value
        end

        # For reasons we don't understand, some parts of the stack are at least once trying to
        # put something that isn't a integer into solr field file_size_is. It is
        # instead an _already serialized_ array of two integers-as-strings, like:
        #
        #      "[\"23169024\", \"23169024\"]"
        #
        # I traced it to this line:
        #    https://github.com/samvera/curation_concerns/blob/v1.7.7/app/indexers/curation_concerns/file_set_indexer.rb#L15
        #
        # Where for some reason `object.file_size[0]` is that weird string representing a serialized
        # array.
        #
        # Warning, future versions of cc/hyrax change the name/type of this key, bah!
        #
        # Can't figure out what is going on, but hacky workaround here:
        file_size_key = "file_size_is"
        candidate_file_size = doc[file_size_key]
        if candidate_file_size && candidate_file_size =~ /(\d+)/
          doc[file_size_key] = $1
        end
      end
    end
  end
end
