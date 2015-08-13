module CHF
  module Utils
    class ParseFields
      
      #helper_method :physical_container_fields, :parse_physical_container

      def self.physical_container_fields
        {'b'=>'box', 'f'=>'folder', 'v'=>'volume', 'p'=>'part'}
      end

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
    end
  end
end
