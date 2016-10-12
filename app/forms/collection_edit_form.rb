class CollectionEditForm < Sufia::Forms::CollectionEditForm

  include HydraEditor::Form
  include HydraEditor::Form::Permissions

  self.terms = [:title, :description, :related_url, :visibility]
  self.required_fields = [:title]

  self.model_class = ::Collection
end
