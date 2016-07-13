# Generated via
#  `rails generate curation_concerns:work GenericWork`
class GenericWork < ActiveFedora::Base
  include ::CurationConcerns::WorkBehavior
  include ::CurationConcerns::BasicMetadata
  include Sufia::WorkBehavior
  self.human_readable_type = 'Work'
  # Change this to restrict which works can be added as a child.
  # self.valid_child_concerns = []
  validates :title, presence: { message: 'Your work must have a title.' }

  # TODO: better way to achieve this?
  # sufia 6 used DC.creator and sufia 7 changed this to DC11.creator, which we were already using.
  property :creator, predicate: ::RDF::Vocab::DC.creator do |index|
    index.as :stored_searchable, :facetable
  end

  # tried this as before_save, but then it didn't show up on metadata form at upload time.
  after_initialize :set_default_metadata

  property :admin_note, predicate: ::RDF::URI.new("http://chemheritage.org/ns/hasAdminNote") do |index|
    index.as :displayable
  end

  property :credit_line, predicate: ::RDF::Vocab::Bibframe.creditsNote do |index|
    index.as :displayable
  end

  property :division, predicate: ::RDF::URI.new("http://chemheritage.org/ns/hasDivision"), multiple: false do |index|
    index.as :displayable
  end

  property :file_creator, predicate: ::RDF::Vocab::EBUCore.hasCreator, multiple: false do |index|
    index.as :displayable
  end

  property :genre_string, predicate: ::RDF::URI.new("http://chemheritage.org/ns/hasGenre") do |index|
    index.as :stored_searchable, :facetable
  end

  #Set up a bunch of MARC Relator codes as properties
  Rails.configuration.makers.merge(Rails.configuration.places).each do |field_name, predicate|
    property field_name, predicate: predicate do |index|
      index.as :stored_searchable
    end
  end

  property :extent, predicate: ::RDF::URI.new("http://chemheritage.org/ns/hasExtent") do |index|
    index.as :stored_searchable
  end

  property :language, predicate: ::RDF::Vocab::DC11.language do |index|
    index.as :stored_searchable, :facetable
  end
  property :medium, predicate: ::RDF::URI.new("http://chemheritage.org/ns/hasMedium") do |index|
    index.as :stored_searchable
  end
  property :physical_container, predicate: ::RDF::Vocab::Bibframe.materialOrganization, multiple: false do |index|
    index.as :stored_searchable
  end

  property :resource_type, predicate: ::RDF::Vocab::DC11.type do |index|
    index.as :stored_searchable, :facetable
  end
  property :rights, predicate: ::RDF::Vocab::DC11.rights do |index|
    index.as :stored_searchable
  end
  property :rights_holder, predicate: ::RDF::URI.new("http://chemheritage.org/ns/hasRightsHolder"), multiple: false do |index|
    index.as :stored_searchable
  end

  property :series_arrangement, predicate: ::RDF::Vocab::Bibframe.materialHierarchicalLevel do |index|
    index.as :displayable
  end

  property :subject, predicate: ::RDF::Vocab::DC11.subject do |index|
    index.as :stored_searchable, :facetable
  end

  # TODO: make this work either via linked data or nested attributes
#  property :genre, predicate: ::RDF::Vocab::EDM.hasType do |index|
#    index.as :stored_searchable, :facetable
#  end

  has_and_belongs_to_many :date_of_work, predicate: ::RDF::Vocab::DC11.date, class_name: "DateOfWork"
  accepts_nested_attributes_for :date_of_work, reject_if: :all_blank, allow_destroy: true

  has_and_belongs_to_many :inscription, predicate: ::RDF::URI.new("http://purl.org/vra/hasInscription"), class_name: "Inscription"
  accepts_nested_attributes_for :inscription, reject_if: :all_blank, allow_destroy: true

  has_and_belongs_to_many :additional_credit, predicate: ::RDF::URI.new("http://chemheritage.org/ns/hasCredit"), class_name: "Credit"
  accepts_nested_attributes_for :additional_credit, reject_if: :all_blank, allow_destroy: true

  # chf edit 2016-02-01 ah
  # Override this from sufia-models/app/models/concerns/sufia/generic_file/batches.rb
  # It's meaningless to define related_files in terms of what sufia6 calls 'batches' ('UploadSets' in sufia 7)
  # However, let's not lose track of the batch_id altgoether just in case we want it for some reason later.
  # word on the street is that this behavior is replaced by works
  # related_files now pulls all sibling relationships
  # https://github.com/projecthydra/curation_concerns/blob/master/app/models/concerns/curation_concerns/file_set/belongs_to_works.rb#L27
  #def related_files
  #  []
  #end

  private

    def set_default_metadata
      self.credit_line = ['Courtesy of CHF Collections']
    end

end
