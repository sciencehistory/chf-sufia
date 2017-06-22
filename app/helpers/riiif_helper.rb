module RiiifHelper
  # use relative url unless we've defind a riiif server in config/environments/*.rb
  def riiif_image_url (file_set_id)
    file_id = FileSet.find(file_set_id).original_file.id
    path = riiif.info_path(file_id, locale: nil)
    if Rails.configuration.respond_to? :riiif_server
      return URI.join(Rails.configuration.riiif_server, path).to_s
    else
      return path
    end
  end
end
