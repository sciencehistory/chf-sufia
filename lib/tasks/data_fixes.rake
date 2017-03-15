require 'chf/data_fixes/work_dates'
require 'chf/data_fixes/add_catlu_access'
require 'chf/data_fixes/strip_strings'

namespace :chf do
  # Most of these are anticipated to be one-time fixes, may get removed
  # from rake later?
  namespace :data_fix do

    desc "Fix Work dates to be Dates"
    task :fix_work_dates => :environment do
      works_updated = []
      progress_bar = ProgressBar.create(total: GenericWork.count, format: "|%B| %p%% %e %t")

      GenericWork.find_each do |w|
        updated = CHF::DataFixes::WorkDates.new(w).change

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

    desc "Add clu@chemheritage.org to all edit_users"
    task :add_catlu_access => :environment do
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

    desc "Strip lead/trail spaces from properties"
    task :strip_spaces => :environment do
      works_updated = []
      progress_bar = ProgressBar.create(total: GenericWork.count, format: "|%B| %p%% %e %t")

      GenericWork.find_each do |w|
        updated = CHF::DataFixes::StripStrings.new(w).change

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
