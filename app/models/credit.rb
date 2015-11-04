class Credit < ActiveFedora::Base
  include Sufia::Noid

  before_save :compose_label

  type ::RDF::URI.new("http://chemheritage.org/ns/credit")
  has_many :generic_files, inverse_of: :additional_credit, class_name: "GenericFile"

  property :role, predicate: ::RDF::URI.new("http://chemheritage.org/ns/hasCreditRole"), multiple: false
  property :name, predicate: ::RDF::Vocab::FOAF.name, multiple: false
  property :label, predicate: ::RDF::SKOS.prefLabel, multiple:false

  def self.role_options
    Sufia.config.credit_roles
  end

  def self.name_options
    Sufia.config.credit_names
  end

  private
    def compose_label
      self.label = "#{self.class.role_options[self.role]} #{self.name}"
    end

end
