module Chf
  module Export
    # Convert an inscription record from a ActiveFedora:Base into a PORO so that the metadata
    #  can be exported in json format using to_json
    #
    class InscriptionConverter
      # Create an instance of an Object containing all the metadata for the inscription
      #
      # @param [Inscription] inscription the inscription associated with one access record
      def initialize(inscription)
        @id = inscription.id
        @location = inscription.location.to_s
        @text = inscription.text.to_s
      end
    end
  end
end
