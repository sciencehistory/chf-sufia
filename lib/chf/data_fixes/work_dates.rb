module CHF
  module DataFixes
    class WorkDates
      attr_reader :work

      def initialize(work)
        @work = work
      end

      # possibly makes changes to work (without saving), returns true
      # if changes were made, so caller can do expensive save.
      def change
        updated = false
        if work.date_uploaded != nil && work.date_uploaded.is_a?(String)
          work.date_uploaded = DateTime.parse(work.date_uploaded)
          updated = true
        end
        if work.date_modified != nil && work.date_modified.is_a?(String)
          work.date_modified = DateTime.parse(work.date_modified)
          updated = true
        end
        return updated
      end
    end
  end
end
