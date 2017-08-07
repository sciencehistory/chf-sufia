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
DownloadsController.class_eval do
  private
  def stream_body(iostream)
    unless response.headers["Last-Modified"] || response.headers["ETag"]
      Rails.logger.warn("Response may be buffered instead of streaming, best to set a Last-Modified or ETag header")
    end

    render nothing: true
    response.body = iostream
  end
end
