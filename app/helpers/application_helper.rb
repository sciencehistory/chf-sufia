module ApplicationHelper
  # A Blacklight facet field helper_method; maps rights URI to String
  # @param [String] facet field uri value
  # @return [String] rights statement label
  def license_label(id)
    service = CurationConcerns::LicenseService.new
    service.label(id)
  end

  # A work uses its thumbnail for preview; file just uses itself.
  def preview_id(presenter)
    (presenter.respond_to?(:thumbnail_id) && presenter.thumbnail_id) ? presenter.thumbnail_id : presenter.id
  end

  def visibility_facet_labels(value)
    case value
    when "open" ; "public"
    when "authenticated" ; "staff-only"
    when "restricted" ; "private"
    else ; value
    end
  end

  # https://stackoverflow.com/a/37347159/307106
  def encoding_safe_content_disposition(file_name)
    "attachment; filename=\"#{file_name.encode("US-ASCII", undef: :replace, replace: "_")}\";filename*=UTF-8''#{URI.encode file_name}"
  end
  module_function :encoding_safe_content_disposition

end
