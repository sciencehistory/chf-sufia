class DateOfWork < TimeSpan
  has_many :generic_files, inverse_of: :date_of_work, class_name: "GenericFile"
end
