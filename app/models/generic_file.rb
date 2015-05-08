class GenericFile < ActiveFedora::Base
  include Sufia::GenericFile

  property :genre, predicate: ::RDF::Vocab::EDM.hasType do |index|
    index.as :stored_searchable, :facetable
  end

end
