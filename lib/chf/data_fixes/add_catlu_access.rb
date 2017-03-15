module CHF
  module DataFixes
    class AddCatluAccess
      attr_reader :work

      def initialize(work)
        @work = work
      end

      # possibly makes changes to work (without saving), returns true
      # if changes were made, so caller can do expensive save.
      def change
        unless work.edit_users.include? "clu@chemheritage.org"
          # << doesn't work on this property in all versions
          work.edit_users = work.edit_users + ["clu@chemheritage.org"]
          return true
        end
        return false
      end
    end
  end
end
