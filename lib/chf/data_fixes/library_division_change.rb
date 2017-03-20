module CHF
  module DataFixes
    class LibraryDivisionChange
      OLD_NAME = "Othmer Library of Chemical History"
      NEW_NAME = "Library"

      attr_reader :work

      def initialize(work)
        @work = work
      end

      # possibly makes changes to work (without saving), returns true
      # if changes were made, so caller can do expensive save.
      def change
        if work.division && work.division.strip == OLD_NAME
          work.division = NEW_NAME
          return true
        end
        return false
      end
    end
  end
end
