# frozen_string_literal: true
module WorkFormBehavior
  extend ActiveSupport::Concern

  class_methods do

    # nested work attributes plus the properties embedded in complex form fields for maker and place
    def build_permitted_params
      super + [
        { date_of_work_attributes: permitted_time_span_params },
        { inscription_attributes: permitted_inscription_params },
        { additional_credit_attributes: permitted_additional_credit_params },
        artist: [],
        author: [],
        addressee: [],
        creator_of_work: [],
        contributor: [],
        engraver: [],
        interviewee: [],
        interviewer: [],
        manufacturer: [],
        photographer: [],
        printer_of_plates: [],
        publisher: [],
        place_of_interview: [],
        place_of_manufacture: [],
        place_of_publication: [],
        place_of_creation: [],
      ]
    end

    def permitted_time_span_params
      [ :id, :_destroy, :start, :start_qualifier, :finish, :finish_qualifier, :note ]
      # tests break when I use this nested structure which I see in other code bases
      #   (probably related to the fact that they are using multivalued fields)
      #[ :id, :_destroy, {
      #  :start => nil, :start_qualifier => nil, :finish => nil, :finish_qualifier => nil, :note => nil
      #}]
    end

    def permitted_inscription_params
      [ :id, :_destroy, :location, :text ]
    end

    def permitted_additional_credit_params
      [ :id, :_destroy, :role, :name ]
    end

    def model_attributes(params)
      # model expects this as multi-value
      params[:rights] = Array(params[:rights])
      clean_params = super #hydra-editor/app/forms/hydra_editor/form.rb:54
      # Oops; we're blanking out these values when changing permissions and probably versions, too
      #  -- they don't have these fields in the form at all so they don't get repopulated.
      clean_params = encode_physical_container(params, clean_params)
      clean_params = encode_external_id(params, clean_params)
      clean_params
    end
  end

  included do

    require_dependency Rails.root.join('lib','chf','utils','parse_fields')

    attr_accessor :maker, :box, :folder, :volume, :part, :place
    CHF::Utils::ParseFields.external_ids_hash.keys.each do |k|
      attr_accessor "#{k}_external_id".to_s
    end

    # give form access to attributes methods so it can build nested forms.
    delegate :date_of_work_attributes=, :to => :model
    delegate :inscription_attributes=, :to => :model
    delegate :additional_credit_attributes=, :to => :model

    def secondary_terms
      []
    end

    # We need these as hidden fields or else data deletion doesn't work.
    def hidden_field_terms
      [:artist,
      :author,
      :addressee,
      :creator_of_work,
      :contributor,
      :engraver,
      :interviewee,
      :interviewer,
      :manufacturer,
      :photographer,
      :printer_of_plates,
      :publisher,
      :place_of_interview,
      :place_of_manufacture,
      :place_of_publication,
      :place_of_creation]
    end

    protected

      # Override HydraEditor::Form to treat nested attbriutes accordingly
      def initialize_field(key)
        if [:inscription, :additional_credit, :date_of_work].include? key
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
