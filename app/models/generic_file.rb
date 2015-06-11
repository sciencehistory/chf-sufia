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

  # TODO: make this work either via linked data or nested attributes
#  property :genre, predicate: ::RDF::Vocab::EDM.hasType do |index|
#    index.as :stored_searchable, :facetable
#  end

end
