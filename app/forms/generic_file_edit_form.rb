class GenericFileEditForm < GenericFilePresenter
  include HydraEditor::Form
  include HydraEditor::Form::Permissions
  include NestedDates

  attr_accessor :maker

  self.required_fields = [:title, :identifier]

  protected

    # Override HydraEditor::Form to treat nested attbriutes accordingly
    def initialize_field(key)
      if reflection = model_class.reflect_on_association(key)
        raise ArgumentError, "Association ''#{key}'' is not a collection" unless reflection.collection?
        build_association(key)
      else
        super
      end
    end

  private

    def build_association(key)
      association = model.send(key)
      if association.empty?
        self[key] = Array(association.build)
      else
        association.build
        self[key] = association
      end
    end

end
