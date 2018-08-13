DownloadsController.class_eval do

  # add our own method for redirecting to S3 url, possibly signed url
  # Since creating these URLs is expensive, we generate links to here, then
  # redirect to S3. Also means we can have bookmarkable non-signed non-expiring
  # links on the actual page.
  #
  # Even though this is in downloads controller and has downloads in name,
  # you can add `&no_content_disposition=true` to header to get a redirect
  # to S3 response that will NOT have content-disposition header forcing download,
  # for using "download" images in a web page. Used for OAI-PMH feed for DPLA.
  def s3_download_redirect
    unless CHF::Env.lookup("image_server_downloads").to_s == "dzi_s3"
      raise ActionController::RoutingError.new('Not Found')
    end

    file_set_id = params[asset_param_key] # params[:id]

    # I thought there was a 'download' or 'downloads' action that is right here,
    # but it's not letting non-logged-in users in, even on public stuff.
    # This works and might match CurationConcerns normal #download auth.
    # If you don't have access you get a weird default icon 'downloaded', but
    # that matches sufia/CC default weirdly.
    authorize! :show, file_set_id

    file_set = FileSet.find(file_set_id)
    file_checksum = file_set.original_file.checksum.value

    filename_base = params[:filename_base].presence || "#{file_set_id}_#{params[:filename_key]}"

    s3_url = CHF::CreateDerivativesOnS3Service.s3_url(
      file_set_id: file_set_id,
      file_checksum: file_checksum,
      type_key: params[:filename_key],
      filename_base: filename_base,
      include_content_disposition: !(params["no_content_disposition"] == "true")
    )

    redirect_to s3_url, status: 302
  end


  private

  # override to add content-disposition to force download for our PDFs, don't want
  # browser displaying them for a 'download' button. BUT also add new param that can
  # override for cases we do.
  #
  # Also add a better filename in http headers than base provides.
  #
  # params["disposition"] == "inline" for inline
  def content_options
    base = super

    extension = Mime::Type.lookup(asset.mime_type)&.symbol&.to_s
    if extension
      download_name = helpers._download_name_base(asset) + ".#{extension}"
      base.merge!(
        filename: download_name,
        disposition: params["disposition"] == "inline" ? "inline" : "attachment"
      )
    end

    base
  end

  # Attempts to get Rails to send HEADERS right away, even with streaming response.
  #
  # Matters cause imgix (and maybe other CDNs?) won't wait more than 10 seconds for headers, although will wait
  # longer to stream body once headers received.
  #
  # Using `response.body=stream` API instead of looped response.stream.write API
  # seems to improve things.
  #
  # Some hints at https://github.com/rails/rails/issues/18714
  #
  # PR'd to hydra-core at https://github.com/samvera/hydra-head/pull/421, remove when on version
  # including it.
  if Gem.loaded_specs["hydra-core"].version > Gem::Version.new("10.5.0") || Gem.loaded_specs["hydra-head"].version > Gem::Version.new("10.5.0")
    Rails.logger.warn "This local patch to hydra-core may no longer be needed, please check, at #{__FILE__}::#{__LINE__}"
  end
  def stream_body(iostream)
    unless response.headers["Last-Modified"] || response.headers["ETag"]
      Rails.logger.warn("Response may be buffered instead of streaming, best to set a Last-Modified or ETag header")
    end

    render nothing: true
    response.body = iostream
  end
end
