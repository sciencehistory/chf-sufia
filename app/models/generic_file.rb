class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile

  property :genre_string, predicate: ::RDF::URI.new("http://chemheritage.org/ns/hasGenre") do |index|
    index.as :stored_searchable, :facetable
  end


  #Set up a bunch of MARC Relator codes as properties
  Creator_contributors = {
    artist:       ::RDF::Vocab::MARCRelators.art,
    author:       ::RDF::Vocab::MARCRelators.aut,
    interviewee:  ::RDF::Vocab::MARCRelators.ive,
    interviewer:  ::RDF::Vocab::MARCRelators.ivr,
    manufacturer: ::RDF::Vocab::MARCRelators.mfr,
    photographer: ::RDF::Vocab::MARCRelators.pht,
  }

  Creator_contributors.each do |field_name, predicate|
    property field_name, predicate: predicate do |index|
      index.as :stored_searchable
    end
  end

  property :creator, predicate: ::RDF::DC11.creator do |index|
    index.as :stored_searchable, :facetable
  end
  property :contributor, predicate: ::RDF::DC11.contributor do |index|
    index.as :stored_searchable, :facetable
  end
  property :date_original, predicate: ::RDF::DC.date do |index|
    index.as :stored_searchable
  end
  property :date_published, predicate: ::RDF::DC.issued do |index|
    index.as :stored_searchable
  end

  property :extent, predicate: ::RDF::DC.extent do |index|
    index.as :stored_searchable
  end

  property :language, predicate: ::RDF::DC11.language do |index|
    index.as :stored_searchable, :facetable
  end
  property :medium, predicate: ::RDF::DC.medium do |index|
    index.as :stored_searchable
  end
  property :physical_container, predicate: ::RDF::Vocab::Bibframe.materialHierarchicalLevel, multiple: false do |index|
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
  property :publisher, predicate: ::RDF::DC11.publisher do |index|
    index.as :stored_searchable, :facetable
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

  property :subject, predicate: ::RDF::DC11.subject do |index|
    index.as :stored_searchable, :facetable
  end


  # TODO: make this work either via linked data or nested attributes
#  property :genre, predicate: ::RDF::Vocab::EDM.hasType do |index|
#    index.as :stored_searchable, :facetable
#  end

end
