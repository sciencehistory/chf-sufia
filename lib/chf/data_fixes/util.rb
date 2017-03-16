module CHF
  module DataFixes
    module Util

      # Generic utility code for updating all GenericWorks, with a progress
      # bar.  Caller must yield a block that takes a single GeneircWork, possibly
      # updates it in place (without #save'ing), and returns true only if it
      # was updated.
      def self.update_works
        works_updated = []
        progress_bar = ProgressBar.create(total: GenericWork.count, format: "|%B| %p%% %e %t")

        GenericWork.find_each do |w|
          updated = yield(w)

          if updated
            w.save
            works_updated << w.id
            progress_bar.title = "#{works_updated.count} saved"
          end
          progress_bar.increment
        end

        progress_bar.finish
        $stderr.puts "Updated #{works_updated.count} works"
      end
    end
  end
end
