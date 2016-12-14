class Inscription < ActiveFedora::Base

  before_save :compose_label

  type ::RDF::URI.new("http://purl.org/vra/Inscription")
  has_many :generic_works, inverse_of: :inscription, class_name: "GenericWork"

  property :location, predicate: ::RDF::URI.new("http://purl.org/vra/location"), multiple: false
  property :text, predicate: ::RDF::URI.new("http://purl.org/vra/text"), multiple: false
  property :display_label, predicate: ::RDF::Vocab::SKOS.prefLabel, multiple:false

  private
    def compose_label
      self.display_label = "(#{self.location}) \"#{self.text}\""
    end

end
