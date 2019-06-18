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

    if file_set.original_file.mime_type =~ /audio/
      deriv_service_class = CHF::AudioDerivativeMaker
    else
      deriv_service_class = CHF::CreateDerivativesOnS3Service
    end

    s3_url = deriv_service_class.s3_url(
      file_set_id: file_set_id,
      file_checksum: file_checksum,
      type_key: params[:filename_key],
      filename_base: filename_base,
      include_content_disposition: !(params["no_content_disposition"] == "true")
    )

    redirect_to s3_url, status: 302
  end


  # A content-disposition filename based on the **FileSet title**. Used for audio files,
  # rather than the filename based on the WORK TITLE as used for other files.
  #
  # @param item [FileSet or FileSetPresenter] an audio item being requested for download
  #
  # @param derivative_extension [String] optional, the file extension for the derivative being
  # downloaded, if not given extension based on original file mime type will be used,if found.
  #
  # @return [String] a filename suitable for download. Literal string, still needs to be
  # escaped/prepped for actual content-disposition header literal.
  #
  # @example The filename for an mp3 derivative
  #   "DownloadsController.download_filename_on_fileset(member, 'mp3')" #=> "the_title_of_the_file.mp3"
  #
  # @example The filename for an original
  #   "DownloadsController.download_filename_on_fileset(member)" #=> "the_title_of_the_file.flac"
  #
  # Note similar method _download_name_base in app/helpers/image_service_helper.rb, used
  # for non-audio download filenames, based on containing WORK TITLE.
  def self.download_filename_on_fileset(item, extension=nil)
    original_extension = Mime::Type.lookup(item.mime_type)&.symbol&.to_s

    # If needed, strip the filename of its original extension:
    # that way, we don't end up with e.g. file_name.flac.mp3.
    base = item.title.first
    if base.end_with? ".#{original_extension}"
      base = File.basename(base, ".#{original_extension}")
    end

    # Now add underscores and, if needed, the extension we want.
    extension = original_extension if extension.blank?

    base = base.gsub(/[']/, ''). # get rid of apostrophes
      gsub(/([[:space:]]|[[:punct:]])+/, '_'). # replace spaces and punctuation w/ underscores
      gsub(/^[_]+|[_]+$/, ''). # but get rid of leading and trailing underscordes.
      downcase

    return base if extension.blank?
    return base if base.end_with? ".#{extension}"
    "#{base}.#{extension}"
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

    base[:disposition] = params["disposition"] == "inline" ? "inline" : "attachment"

    # Note any mime type you want to deliver as a download should be registered
    # in ./config/initializers/mime_types.rb
    extension = Mime::Type.lookup(asset.mime_type)&.symbol&.to_s

    if asset.mime_type.present? && asset.mime_type =~ /^audio/
      download_name = self.class.download_filename_on_fileset(asset)
    elsif extension
      download_name = helpers._download_name_base(asset) + ".#{extension}"
    end

    if download_name
      base[:filename] = download_name
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
