class CollectionEditForm
  include HydraEditor::Form
  self.model_class = ::Collection
  self.terms = [:title, :description, :related_url]
  self.required_fields = [:title]
  # Test to see if the given field is required
  # @param [Symbol] key a field
  # @return [Boolean] is it required or not
  def required?(key)
    model_class.validators_on(key).any?{|v| v.kind_of? ActiveModel::Validations::PresenceValidator}
  end
end
