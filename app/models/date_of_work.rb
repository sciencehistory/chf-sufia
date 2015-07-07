class DateOfWork < TimeSpan
  belongs_to :is_work_date_of, predicate: ::RDF::URI.new("http://chemheritage.org/ns/work_date_of"), class_name: 'GenericFile'
end
