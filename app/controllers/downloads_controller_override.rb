DownloadsController.class_eval do

  # add our own method for redirecting to S3 url, possibly signed url
  # Since creating these URLs is expensive, we generate links to here, then
  # redirect to S3. Also means we can have bookmarkable non-signed non-expiring
  # links on the actual page.
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
      filename_key: params[:filename_key],
      suffix: ".jpg",
      filename_base: filename_base
    )

    redirect_to s3_url, status: 302
  end


  private

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
