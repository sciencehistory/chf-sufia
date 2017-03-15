require 'chf/data_fixes/work_dates'
require 'chf/data_fixes/add_catlu_access'
require 'chf/data_fixes/strip_strings'

namespace :chf do
  # Most of these are anticipated to be one-time fixes, may get removed
  # from rake later?
  namespace :data_fix do

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
  end
end
