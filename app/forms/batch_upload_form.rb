class BatchUploadForm < Sufia::Forms::BatchUploadForm
  require_dependency Rails.root.join('lib','chf','utils','parse_fields')

  attr_accessor :maker, :box, :folder, :volume, :part, :place
  CHF::Utils::ParseFields.external_ids_hash.keys.each do |k|
    attr_accessor "#{k}_external_id".to_s
  end

  # give form access to attributes methods so it can build nested forms.
  delegate :date_of_work_attributes=, :to => :model
  delegate :inscription_attributes=, :to => :model
  delegate :additional_credit_attributes=, :to => :model

  # note we remove title and resource_type which would be set on a per-work basis.
  def self.chf_terms
    [:identifier, :maker,
      :date_of_work,
      :place,
      :genre_string,
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

  self.terms += chf_terms
  self.required_fields = [:identifier]

  def primary_terms
    self.class.chf_terms
  end

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
    :interviewee,
    :interviewer,
    :manufacturer,
    :photographer,
    :publisher,
    :place_of_interview,
    :place_of_manufacture,
    :place_of_publication,
    :place_of_creation]
  end

  # nested work attributes plus the properties embedded in complex form fields for maker and place
  def self.build_permitted_params
    super + [
      { date_of_work_attributes:
        [ :id, :_destroy, :start, :start_qualifier, :finish, :finish_qualifier, :note ]
      },
      { inscription_attributes: [ :id, :_destroy, :location, :text ] },
      { additional_credit_attributes: [ :id, :_destroy, :role, :name ] },
      artist: [],
      author: [],
      addressee: [],
      creator_of_work: [],
      contributor: [],
      interviewee: [],
      interviewer: [],
      manufacturer: [],
      photographer: [],
      publisher: [],
      place_of_interview: [],
      place_of_manufacture: [],
      place_of_publication: [],
      place_of_creation: [],
    ]
  end

  protected

#    # Override HydraEditor::Form to treat nested attbriutes accordingly
#    def initialize_field(key)
#      if [:inscription, :additional_credit, :date_of_work].include? key
#        build_association(key)
#      else
#        super
#      end
#    end

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
