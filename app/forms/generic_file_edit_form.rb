class GenericFileEditForm < GenericFilePresenter
  include HydraEditor::Form
  include HydraEditor::Form::Permissions
  include NestedAttrs
  include ApplicationHelper

  attr_accessor :maker, :box, :folder, :volume, :part, :place
  CHF::Utils::ParseFields.external_ids_hash.keys.each do |k|
    attr_accessor "#{k}_external_id".to_s
  end

  self.required_fields = [:title, :identifier]

  def self.model_attributes(params)
    clean_params = super #hydra-editor/app/forms/hydra_editor/form.rb:54
    # Oops; we're blanking out these values when changing permissions and probably versions, too
    #  -- they don't have these fields in the form at all so they don't get repopulated.
    clean_params = encode_physical_container(params, clean_params)
    clean_params = encode_external_id(params, clean_params)
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
    def self.encode_physical_container(params, clean_params)
      have_data = false
      result = []
      CHF::Utils::ParseFields.physical_container_fields.values.each do |k|
        # check for some data
        if params[k].present?
          have_data = true
          result << "#{k[0]}#{params[k]}"
        end
      end
      if have_data
        clean_params['physical_container'] = result.join('|')
      end
      clean_params
    end

    # It's a multi-value field
    def self.encode_external_id(params, clean_params)
    #unless params['identifier'].nil?
      have_data = false
      result = []
      CHF::Utils::ParseFields.external_ids_hash.keys.each do |k|
        param = "#{k}_external_id"
        if params[param].present?
          have_data = true
          params[param].each do |id_value|
            result << "#{k}-#{id_value}" unless id_value.empty?
          end
        end
      end
      if have_data
        clean_params['identifier'] = result
      end
      clean_params
    end

end
