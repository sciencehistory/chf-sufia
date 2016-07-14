# Generated via
#  `rails generate curation_concerns:work GenericWork`
module CurationConcerns
  class GenericWorkForm < Sufia::Forms::WorkForm
    self.model_class = ::GenericWork

    # this list of terms is used for:
    #   allowing the fields to be edited
    #   TODO: dry this up? was previous in a presenter. do something like
    #   https://github.com/aic-collections/aicdams-lakeshore/blob/cf197cab2b2f65f0841cbc61573ed8ef7c576c48/app/presenters/work_presenter.rb?
    self.terms += [:title, :identifier,
      ].concat(Rails.configuration.makers.keys).concat(
        [:date_of_work]).concat(
        Rails.configuration.places.keys).concat(
        [
        :resource_type, :genre_string,
        :medium,
        :extent,
        :language,
        :description,
        :inscription,
        :subject,
        :division,
        :series_arrangement,
        :physical_container,
        :related_url,
        :rights,
        :rights_holder,
        :credit_line,
        :additional_credit,
        :file_creator,
        :admin_note,
        ])

    # Add a new list for creating form elements on the edit pages
    #   (since we've combined many of the fields into 'maker')
    def edit_field_terms
      [:title, :identifier, :maker,
        :date_of_work,
        :place,
        :resource_type, :genre_string,
        :medium,
        :extent,
        :language,
        :description,
        :inscription,
        :subject,
        :division,
        :series_arrangement,
        :physical_container,
        :related_url,
        :rights,
        :rights_holder,
        :credit_line,
        :additional_credit,
        :file_creator,
        :admin_note,
      ]
    end

    # We need these as hidden fields or else data deletion doesn't work.
    def hidden_field_terms
      Rails.configuration.makers.keys.concat(Rails.configuration.places.keys)
    end

    # post-upload edit form has a "show more" button; we want
    # to control order independently here.
    def above_fold_terms
      [:identifier,
      :maker,
      :date_of_work,
      :resource_type,
      :genre_string,
      ]
    end
    def below_fold_terms
      edit_field_terms - above_fold_terms - [:title]
    end

    # give form access to attributes methods so it can build nested forms.
    delegate :date_of_work_attributes=, :to => :model
    delegate :inscription_attributes=, :to => :model
    delegate :additional_credit_attributes=, :to => :model


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

#      # Override HydraEditor::Form to treat nested attbriutes accordingly
#      def initialize_field(key)
#        if reflection = model_class.reflect_on_association(key)
#          raise ArgumentError, "Association ''#{key}'' is not a collection" unless reflection.collection?
#          build_association(key)
#        else
#          super
#        end
#      end

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
        result = []
        CHF::Utils::ParseFields.physical_container_fields.values.each do |k|
          # check for some data
          if params[k].present?
            result << "#{CHF::Utils::ParseFields.physical_container_fields_reverse[k]}#{params[k]}"
          end
        end
        unless result.empty?
          clean_params['physical_container'] = result.join('|')
        end
        clean_params
      end

      # It's a multi-value field
      def self.encode_external_id(params, clean_params)
      #unless params['identifier'].nil?
        result = []
        CHF::Utils::ParseFields.external_ids_hash.keys.each do |k|
          param = "#{k}_external_id"
          if params[param].present?
            params[param].each do |id_value|
              result << "#{k}-#{id_value}" unless id_value.empty?
            end
          end
        end
        unless result.empty?
          clean_params['identifier'] = result
        end
        clean_params
      end


  end
end
