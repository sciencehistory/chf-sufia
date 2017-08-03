# TEMPORARY, we want to see what headers and such imgix is sending
DownloadsController.before_action do |controller|
  Rails.logger.info "Download URI headers: #{controller.request.url}: headers: #{controller.request.headers.to_h.delete_if { |k, v| ! v.is_a?(String) }}"
end

# Less temporary, cache long headers on things delivered by downloads action,
# this may only apply to originals at present, not sure, stack code is convoluted.
#
# TODO: If fileset changes images but keeps id, this is cached too long. Add
# cache-busting element to URI, perhaps based on existing fingerprint
# we already have from fedora.

DownloadsController.before_action only: :show do |controller|
  # not sure about HTTP_RANGE, just leave it out for now.
  controller.expires_in(1.year, :public => true) unless controller.request.headers['HTTP_RANGE'].present?
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
# PR'd to hydra-core at https://github.com/samvera/hydra-head/pull/421
# If it gets merged we should put a live warning here to expected hydra-head release.
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
