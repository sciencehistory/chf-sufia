module CHF
  module DataFixes
    class StripStrings
      attr_reader :work

      def initialize(work)
        @work = work
      end

      # possibly makes changes to work (without saving), returns true
      # if changes were made, so caller can do expensive save.
      def change
        updated = false
        work.attributes.keys.each do |property|
          if work.send(property).is_a?(Array)
            work.send("#{property}=", work.send(property).collect do |val|
              if val.is_a?(String) && val.strip != val
                updated = true
                val.strip
              else
                val
              end
            end)
          elsif work.send(property).is_a?(String)
            if work.send(property) != work.send(property).strip
              updated = true
              work.send("#{property}=", work.send(property).strip)
            end
          end
        end
       return updated
      end
    end
  end
end
