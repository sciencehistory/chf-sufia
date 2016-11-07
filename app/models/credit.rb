class Credit < ActiveFedora::Base

  before_save :compose_label

  type ::RDF::URI.new("http://chemheritage.org/ns/credit")
  has_many :generic_works, inverse_of: :additional_credit, class_name: "GenericWork"

  property :role, predicate: ::RDF::URI.new("http://chemheritage.org/ns/hasCreditRole"), multiple: false
  property :name, predicate: ::RDF::Vocab::FOAF.name, multiple: false
  property :label, predicate: ::RDF::Vocab::SKOS.prefLabel, multiple:false

  def self.role_options
    Rails.configuration.credit_roles
  end

  def self.name_options
    Rails.configuration.credit_names
  end

  private
    def compose_label
      self.label = "#{self.class.role_options[self.role]} #{self.name}"
    end

end
