class Inscription < ActiveFedora::Base
  include Sufia::Noid

  type ::RDF::URI.new("http://purl.org/vra/Inscription")
  has_many :generic_works, inverse_of: :inscription, class_name: "GenericWork"

  property :location, predicate: ::RDF::URI.new("http://purl.org/vra/location"), multiple: false
  property :text, predicate: ::RDF::URI.new("http://purl.org/vra/text"), multiple: false
end
