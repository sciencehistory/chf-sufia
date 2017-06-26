module RiiifHelper
  # use relative url unless we've defind a riiif server in config/environments/*.rb
  def riiif_image_url (riiif_file_id)
    path = riiif.info_path(riiif_file_id, locale: nil)
    if Rails.configuration.respond_to? :riiif_server
      return URI.join(Rails.configuration.riiif_server, path).to_s
    else
      return path
    end
  end

end
