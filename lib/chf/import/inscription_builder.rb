module Chf
  module Import
    class InscriptionBuilder

      # Build Inscriptions on a Work based on json metadata
      #
      #  @param Array[hash] json_inscs An array of hashes with the below keys
      #  @option :location
      #  @option :text
      #  @option :id       - not used - Id for the permissions is generated
      def build(work, json_inscs)
        inscs = Array.new
        json_inscs.each do |insc|
          inscs << create(insc)
        end
        work.inscription = inscs if !inscs.empty?
      end

      private

        def create(insc_hash)
          insc = Inscription.new

          insc.location = insc_hash[:location]
          insc.text = insc_hash[:text]
          insc
        end

    end
  end
end
