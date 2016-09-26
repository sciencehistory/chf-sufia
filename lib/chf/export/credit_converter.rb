module Chf
  module Export
    # Convert a credit record from a ActiveFedora:Base into a PORO so that the metadata
    #  can be exported in json format using to_json
    #
    class CreditConverter
      # Create an instance of a Object Credit containing all the metadata for the credit
      #
      # @param [Credit] credit the credit associated with one access record
      def initialize(credit)
        @id = credit.id
        @role = credit.role.to_s
        @name = credit.name.to_s
        @label = credit.label.to_s
      end
    end
  end
end
