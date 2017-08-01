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
