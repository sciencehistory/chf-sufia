class DateOfPublication < TimeSpan
  belongs_to :is_publication_date_of, predicate: ::RDF::URI.new("http://chemheritage.org/ns/publication_date_of"), class_name: 'GenericFile'
end
