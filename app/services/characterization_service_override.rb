# override https://github.com/samvera/hydra-works/blob/v0.16.0/lib/hydra/works/services/characterization_service.rb
# to keep our multi-layer tiffs from causing problems
module Hydra::Works
  class CharacterizationService
    protected
      def append_property_value(property, value)
        value = object.send(property) + [value] unless property == :mime_type
        # We don't want multiple heights / widths, it doesn't make sense.
        value = [object.send(property).to_a.concat(value).max] if property == :height or property == :width
        object.send("#{property}=", value)
      end
  end
end
