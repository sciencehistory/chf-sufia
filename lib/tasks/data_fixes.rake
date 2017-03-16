require 'chf/data_fixes/util'
require 'chf/data_fixes/work_dates'
require 'chf/data_fixes/add_catlu_access'
require 'chf/data_fixes/strip_strings'

namespace :chf do
  # Most of these are anticipated to be one-time fixes, may get removed
  # from rake later?
  namespace :data_fix do


    desc "Bulk fix a variety of things"
    task :bulk_fix => :environment do
      # Apply a variety of fixes in one pass, to go quicker.
      # what fixes are included may change from time to time,
      # most of these are run-once things.
      CHF::DataFixes::Util.update_works do |w|
        [ CHF::DataFixes::WorkDates.new(w).change,
          CHF::DataFixes::AddCatluAccess.new(w).change,
          CHF::DataFixes::StripStrings.new(w).change
        ].any?
      end
    end

    desc "Fix Work dates to be Dates"
    task :fix_work_dates => :environment do
      CHF::DataFixes::Util.update_works do |w|
        CHF::DataFixes::WorkDates.new(w).change
      end
    end

    desc "Add clu@chemheritage.org to all edit_users"
    task :add_catlu_access => :environment do
      CHF::DataFixes::Util.update_works do |w|
        CHF::DataFixes::AddCatluAccess.new(w).change
      end
    end

    desc "Strip lead/trail spaces from properties"
    task :strip_spaces => :environment do
      CHF::DataFixes::Util.update_works do |w|
        CHF::DataFixes::StripStrings.new(w).change
      end
    end


    desc "'Othmer...' to 'Library' in division"
    task :library_division => :environment do
      works_updated = []
      progress_bar = ProgressBar.create(total: GenericWork.count, format: "|%B| %p%% %e %t")

      GenericWork.find_each do |w|
        updated = CHF::DataFixes::AddCatluAccess.new(w).change

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
