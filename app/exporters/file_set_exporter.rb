class FileSetExporter < Exporter
  def edit_hash(h)
    h['file_url'] = file_url
    h['sha_1'] = sha_1
    h
  end


  # Fun fact: if you upload a new version of a file to a FileSet,
  # the number of items in the_file_set.files array does NOT change.
  # Instead, a reference to the latest version of the file
  # replaces the single element in the array.

  def file_url()
    target_item.files.last.uri.to_s
  end

  def sha_1()
    sha_1_string = target_item.files.last.file_hash.last.id
    raise RuntimeError, "SHA-1 hash not found for FileSet #{target_item.id}" unless sha_1_string.start_with? 'urn:sha1:'
    sha_1_string.sub(/^urn:sha1:/, '')
  end

  def self.exportee()
    return FileSet
  end

end
