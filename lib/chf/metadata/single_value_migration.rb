module CHF
  module Metadata
    class SingleValueMigration

      # Merge descrptions into one field.
      def self.run
        GenericWork.find_each do |w|
          puts "#{w.id}: #{w.title.count} titles, #{w.description.count} descriptions"

          descriptions = w.description.to_a
          # join returns "" if the array was empty, which results in a changed record.
          w.description = Array.wrap(descriptions.join("\r\n\r\n")) if descriptions.count > 1

          titles = w.title.to_a
          additional_titles = w.additional_title.to_a + titles.slice!(1, titles.size)
          w.additional_title = additional_titles
          w.title = titles

          w.save if w.changed?
        end
      end

    end
  end
end
