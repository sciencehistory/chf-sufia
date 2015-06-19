class GenericFileEditForm < GenericFilePresenter
  include HydraEditor::Form
  include HydraEditor::Form::Permissions

  self.required_fields = [:title, :identifier]
end
