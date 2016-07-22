module CHF
  module Utils
    class ParseFields

      # turn something like "b9879|f9876655|v65464|p24" into
      #   something like {"b"=>"9879", "f"=>"9876655", "v"=>"65464", "p"=>"24"}
      def self.parse_physical_container(str)
        return {} unless str.present?
        components = str.split('|')
        pc_hash = {}
        components.each do |s|
          pc_hash[s[0]] = s[1..-1]
        end
        pc_hash
      end

      # turn something like ['object-2008.043.002', 'object-2008.043.003']
      # into [['object', '2008.043.002'], ['object', '2008.043.003']]
      def self.parse_external_ids(list)
        parsed_ids = []
        list.each do |str|
          parsed_ids << parse_external_id(str) unless str.empty?
        end
        parsed_ids
      end

      # return an array like ['object', '2008.043.003']
      # TODO: Or return...? parse error?
      def self.parse_external_id(str)
        components = str.split('-', 2)
        [components[0], components[1]]
      end

      def self.parse_external_ids_for_form(list)
        parse_external_ids(list).map { |pair| ["#{pair[0]}_external_id", pair[1]] }
      end

      def self.physical_container_fields
        Rails.configuration.physical_container_fields
      end
      def self.physical_container_fields_reverse
        Hash[*CHF::Utils::ParseFields.physical_container_fields.to_a.flatten.reverse]
      end

      def self.external_ids_hash
        Rails.configuration.external_ids_hash
      end

    end
  end
end
