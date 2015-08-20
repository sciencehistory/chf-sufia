class GenericFileEditForm < GenericFilePresenter
  include HydraEditor::Form
  include HydraEditor::Form::Permissions
  include NestedDates
  include ApplicationHelper

  attr_accessor :maker, :box, :folder, :volume, :part
  CHF::Utils::ParseFields.external_ids_hash.keys.each do |k|
    attr_accessor "#{k}_external_id".to_s
  end

  self.required_fields = [:title, :identifier]

  def self.model_attributes(params)
    clean_params = super #hydra-editor/app/forms/hydra_editor/form.rb:54
    clean_params["physical_container"] = encode_physical_container params
    clean_params["identifier"] = encode_external_id params
    clean_params
  end

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

    # It's a single-value field
    def self.encode_physical_container(params)
      result = []
      CHF::Utils::ParseFields.physical_container_fields.values.each do |k|
        result << "#{k[0]}#{params[k]}" if params[k].present?
      end
      result.join('|')
    end

    # It's a multi-value field
    def self.encode_external_id(params)
      result = []
      CHF::Utils::ParseFields.external_ids_hash.keys.each do |k|
        param = "#{k}_external_id"
        if params[param].present?
          params[param].each do |id_value|
            result << "#{k}-#{id_value}" unless id_value.empty?
          end
        end
      end
      result
    end

end
