# TEMPORARY, we want to see what headers and such imgix is sending

DownloadsController.before_action do |controller|
  Rails.logger.info "Download URI headers: #{controller.request.url}: headers: #{controller.request.headers.to_h.delete_if { |k, v| ! v.is_a?(String) }}"
end
