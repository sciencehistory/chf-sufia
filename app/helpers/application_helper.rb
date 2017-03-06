module ApplicationHelper
  # A Blacklight facet field helper_method; maps rights URI to String
  # @param [String] facet field uri value
  # @return [String] rights statement label
  def license_label(id)
    service = CurationConcerns::LicenseService.new
    service.label(id)
  end
end
