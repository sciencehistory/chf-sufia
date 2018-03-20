class DateOfWork < TimeSpan
  include ActiveModel::Serializers::JSON

  has_many :generic_works, inverse_of: :date_of_work, class_name: "GenericWork"
end
