class FileSetExporter < Exporter
  def edit_hash(h)
    h['file_urls'] = file_urls
    h
  end

  def file_urls()
    # target_item.files.collect{|f| f.uri.to_s}
    ["https://digital.sciencehistory.org/downloads/#{target_item.id}"]
  end

  def self.exportee()
    return FileSet
  end

end
