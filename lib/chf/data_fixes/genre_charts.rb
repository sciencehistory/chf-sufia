module CHF
  module DataFixes
    class GenreCharts
      OLD_VALUE = "Diagrams"
      NEW_VALUE = "Charts, diagrams, etc"

      attr_reader :work

      def initialize(work)
        @work = work
      end

      # possibly makes changes to work (without saving), returns true
      # if changes were made, so caller can do expensive save.
      def change
        if work.genre_string.include? OLD_VALUE
          # << doesn't work on this property in all versions
          work.genre_string = work.genre_string.map { |s| s == OLD_VALUE ? NEW_VALUE : s }
          return true
        end
        return false
      end
    end
  end
end
