class BatchEditForm < Sufia::Forms::BatchEditForm
  require_dependency Rails.root.join('lib','chf','utils','parse_fields')

  CHF::Utils::ParseFields.external_ids_hash.keys.each do |k|
    attr_accessor "#{k}_external_id".to_s
  end

  self.terms = [
    # Single-value fields don't work
    #:division,
    #:physical_container,
    #:rights_holder,
    #:file_creator,
    :additional_title,
    :identifier,
    :admin_note,
    # Nested attributes don't work
    #:date_of_work,
    #:inscription,
    #:additional_credit,
    :resource_type,
    :subject, :language,
    :related_url,
    :after,
    :artist,
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
    :place_of_creation,
    :genre_string,
    :medium,
    :extent,
    :series_arrangement,
    :rights
  ]

  self.required_fields = []

  def self.model_attributes(params)
    clean_params = super #hydra-editor/app/forms/hydra_editor/form.rb:54
    # model expects this as multi-value
    params[:rights] = Array(params[:rights]) if params[:rights].present?
    clean_params = encode_external_id(params, clean_params)
    clean_params.keys.each do |key|
      # strip ALL the things!
      if clean_params[key].is_a?(Array)
        clean_params[key].map!(&:strip)
      elsif clean_params[key].is_a?(String)
        clean_params[key] = clean_params[key].strip
      end
    end
    # Permission attributes are getting stripped indiscriminately
    # due to a bug released in sufia 7.3:
    # https://github.com/projecthydra-labs/hyrax/issues/652
    clean_params['permissions_attributes'] = params['permissions_attributes'] if params['permissions_attributes']
    clean_params
  end

  private

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

    # override sufia form's visibility default if we can find a better option
    def initialize_combined_fields
      super
      model.visibility = set_batch_visibility
    end

    # Return a value for visibility only if all the items in the batch have the same value.
    def set_batch_visibility
      range = batch_document_ids.map{ |doc_id| model_class.find(doc_id).visibility }.uniq
      return nil if range.count > 1
      range.first
    end
end
