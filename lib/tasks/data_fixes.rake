require 'chf/data_fixes/util'
require 'chf/data_fixes/work_dates'
require 'chf/data_fixes/strip_strings'
require 'chf/data_fixes/genre_document'

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
        [
          CHF::DataFixes::WorkDates.new(w).change,
          CHF::DataFixes::StripStrings.new(w).change,
          CHF::DataFixes::LibraryDivisionChange.new(w).change,
          CHF::DataFixes::GenreDocument.new(w).change
        ].any?
      end
    end

    desc "Fix Work dates to be Dates"
    task :fix_work_dates => :environment do
      CHF::DataFixes::Util.update_works do |w|
        CHF::DataFixes::WorkDates.new(w).change
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
      CHF::DataFixes::Util.update_works do |w|
        CHF::DataFixes::LibraryDivisionChange.new(w).change
      end
    end

    desc "Genre 'Records (Documents)' to 'Documents'"
    task :genre_document => :environment do
      CHF::DataFixes::Util.update_works do |w|
        CHF::DataFixes::GenreDocument.new(w).change
      end
    end

    desc "Replace non-allowed html tags in description"
    task :description_html => :environment do
      CHF::DataFixes::Util.update_works do |w|
        if w.description.any? { |d| d =~ %r{<p>|</p>|<em>|</em>|<strong>|</strong>} }
          w.description = w.description.collect do |d|
            d.gsub("<p>", "\r\n\r\n").
              gsub("</p>", "").
              gsub("<em>", "<i>").
              gsub("</em>", "</i>").
              gsub("<strong>", "<b>").
              gsub("</strong>", "</b>").
              gsub(/\A\s+/, '') # leading newlines result in empty p
          end
          true
        else
          false
        end
      end
    end


  end
end
