# override https://github.com/samvera/hydra-works/blob/v0.16.0/lib/hydra/works/services/characterization_service.rb
# to keep our multi-layer tiffs from causing problems. The height/width properties
# are included for both 'layers' in the TIFF, we want to make sure we're saving
# the one from the LARGEST layer, assuming that's the "real" layer, and ONLY
# that one.
Hydra::Works::CharacterizationService.class_eval do
  protected
    def append_property_value(property, value)
      value = object.send(property) + [value] unless property == :mime_type
      # We don't want multiple heights / widths, pick the max as the true
      # width/height.
      value = [object.send(property).to_a.concat(value).max] if property == :height or property == :width
      object.send("#{property}=", value)
    end
end
