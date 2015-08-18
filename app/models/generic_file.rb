class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile

  property :genre_string, predicate: ::RDF::URI.new("http://chemheritage.org/ns/hasGenre") do |index|
    index.as :stored_searchable, :facetable
  end

  #Set up a bunch of MARC Relator codes as properties
  Sufia.config.makers.each do |field_name, predicate|
    property field_name, predicate: predicate do |index|
      index.as :stored_searchable
    end
  end

  property :extent, predicate: ::RDF::URI.new("http://chemheritage.org/ns/extent") do |index|
    index.as :stored_searchable
  end

  property :language, predicate: ::RDF::DC11.language do |index|
    index.as :stored_searchable, :facetable
  end
  property :medium, predicate: ::RDF::URI.new("http://chemheritage.org/ns/medium") do |index|
    index.as :stored_searchable
  end
  property :physical_container, predicate: ::RDF::Vocab::Bibframe.materialOrganization, multiple: false do |index|
    index.as :stored_searchable
  end

  property :place_of_interview, predicate: ::RDF::Vocab::MARCRelators.evp do |index|
    index.as :stored_searchable
  end
  property :place_of_manufacture, predicate: ::RDF::Vocab::MARCRelators.mfp do |index|
    index.as :stored_searchable
  end
  property :place_of_publication, predicate: ::RDF::Vocab::MARCRelators.pup do |index|
    index.as :stored_searchable
  end

  property :provenance, predicate: ::RDF::DC.provenance, multiple: false do |index|
    index.as :stored_searchable
  end

  property :resource_type, predicate: ::RDF::DC11.type do |index|
    index.as :stored_searchable, :facetable
  end
  property :rights, predicate: ::RDF::DC11.rights do |index|
    index.as :stored_searchable
  end
  property :rights_holder, predicate: ::RDF::URI.new("http://chemheritage.org/ns/rightsHolder"), multiple: false do |index|
    index.as :stored_searchable
  end

  property :series_arrangement, predicate: ::RDF::Vocab::Bibframe.materialHierarchicalLevel do |index|
    index.as :stored
  end

  property :subject, predicate: ::RDF::DC11.subject do |index|
    index.as :stored_searchable, :facetable
  end

  # TODO: make this work either via linked data or nested attributes
#  property :genre, predicate: ::RDF::Vocab::EDM.hasType do |index|
#    index.as :stored_searchable, :facetable
#  end

# Class names can be inferred since they are the same as the association name.
  has_many :date_of_work, inverse_of: :is_work_date_of, as: 'is_work_date_of'

  accepts_nested_attributes_for :date_of_work, reject_if: :all_blank, allow_destroy: true

end
