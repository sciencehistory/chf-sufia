class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile

  property :admin_notes, predicate: ::RDF::URI.new("http://chemheritage.org/ns/adminNotes") do |index|
    index.as :displayable
  end

  property :credit_line, predicate: ::RDF::Vocab::Bibframe.creditsNote do |index|
    index.as :displayable
  end

  property :division, predicate: ::RDF::URI.new("http://chemheritage.org/ns/division"), multiple: false do |index|
    index.as :displayable
  end

  property :file_creator, predicate: ::RDF::Vocab::EBUCore.hasCreator, multiple: false do |index|
    index.as :displayable
  end

  property :genre_string, predicate: ::RDF::URI.new("http://chemheritage.org/ns/hasGenre") do |index|
    index.as :stored_searchable, :facetable
  end

  #Set up a bunch of MARC Relator codes as properties
  Sufia.config.makers.merge(Sufia.config.places).each do |field_name, predicate|
    property field_name, predicate: predicate do |index|
      index.as :stored_searchable
    end
  end

  property :extent, predicate: ::RDF::URI.new("http://chemheritage.org/ns/extent") do |index|
    index.as :stored_searchable
  end

  property :language, predicate: ::RDF::Vocab::DC11.language do |index|
    index.as :stored_searchable, :facetable
  end
  property :medium, predicate: ::RDF::URI.new("http://chemheritage.org/ns/medium") do |index|
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
  property :rights_holder, predicate: ::RDF::URI.new("http://chemheritage.org/ns/rightsHolder"), multiple: false do |index|
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

end
