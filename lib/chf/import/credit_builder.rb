module Chf
  module Import
    class CreditBuilder

      # Build Credits on a Work based on json metadata
      #
      #  @param Array[hash] json_creds An array of hashes with the below keys
      #  @option :role
      #  @option :name
      #  @option :label
      #  @option :id       - not used - Id for the permissions is generated
      def build(work, json_creds)
        creds = Array.new
        json_creds.each do |cred|
          creds << create(cred)
        end
        work.additional_credit = creds if !creds.empty?
      end

      private

        def create(cred_hash)
          cred = Credit.new

          cred.role = cred_hash[:role]
          cred.name = cred_hash[:name]
          cred.display_label = cred_hash[:label]
          cred
        end

    end
  end
end
