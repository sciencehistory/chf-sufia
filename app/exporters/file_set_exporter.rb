class FileSetExporter < Exporter
  def edit_hash(h)
    h['file_urls'] = file_urls
    h
  end

  def file_urls()
    [Rails.application.routes.url_helpers.download_url(target_item.id)]
  end

  def self.exportee()
    return FileSet
  end
end
