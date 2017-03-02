module CHF
  module Metadata
    class RelatedUrlReport

      # array of id, title, url pairs
      def data
        data = []

        GenericWork.find_each do |w|
          w.related_url.each do |url|
            data << [w.id, w.title.first, url]
          end
        end

        return data
      end

      def to_csv(filepath)
        CSV.open(filepath, "wb") do |csv|
          data.each do |row|
            csv << row
          end
        end
      end
    end
  end
end
