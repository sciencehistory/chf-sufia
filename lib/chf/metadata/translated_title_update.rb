module CHF
  module Metadata
    class TranslatedTitleUpdate

      attr_accessor :matches
      # regex breaks up phrases with brackets
      RE = /(.*)\[(.*)\](.*)/

      def initialize
        @matches = {}
      end

      def run
        GenericWork.find_each do |w|
          matcher = RE.match(w.title.first)
          unless matcher.nil?
            @matches[w.id] = {
              title: matcher[1].strip,
              additional: matcher[2],
              rest: matcher[3].strip
            }
          end
        end
      end

    end
  end
end
