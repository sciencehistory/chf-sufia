class FileSetExporter < Exporter
  def edit_hash(h)
    h['file_url']            = file_url
    h['sha_1']               = sha_1
    h['title_for_export']    = title_for_export
    h['filename_for_export'] = filename_for_export
    raise RuntimeError, "No title for FileSet #{target_item.id}"    if h['title_for_export'].nil?
    raise RuntimeError, "No filename for FileSet #{target_item.id}" if h['filename_for_export'].nil?
    h
  end

  def title_for_export
    return target_item.title.first unless target_item.title.nil? || target_item.title == []
    # Otherwise fall back on
    filename_for_export
  end

  # This should always be a non-empty string.
  def filename_for_export
    return "No file attached to this asset" if target_item.files.empty?
    target_item.original_file.file_name.first
  end

  # Fun fact: if you upload a new version of a file to a FileSet,
  # the number of items in the_file_set.files array does NOT change.
  # Instead, a reference to the latest version of the file
  # replaces the single element in the array.

  def file_url
    return nil if target_item.files.empty?
    target_item.files.last.uri.to_s
  end

  def sha_1
    return nil if target_item.files.empty?
    sha_1_string = target_item.files.last.file_hash.last.id
    raise RuntimeError, "SHA-1 hash not found for FileSet #{target_item.id}" unless sha_1_string.start_with? 'urn:sha1:'
    sha_1_string.sub(/^urn:sha1:/, '')
  end

  def self.exportee
    return FileSet
  end

end
