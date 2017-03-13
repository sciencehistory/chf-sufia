

namespace :chf do
  # Most of these are anticipated to be one-time fixes, may get removed
  # from rake later?
  namespace :data_fix do
    desc "Fix Work dates to be Dates"
    task :fix_work_dates => :environment do
      works_updated = []
      progress_bar = ProgressBar.create(total: GenericWork.count, format: "|%B| %p%% %e %t")

      GenericWork.find_each do |w|
        updated = false
        if w.date_uploaded != nil && w.date_uploaded.is_a?(String)
          w.date_uploaded = DateTime.parse(w.date_uploaded)
          updated = true
        end
        if w.date_modified != nil && w.date_modified.is_a?(String)
          w.date_modified = DateTime.parse(w.date_modified)
          updated = true
        end
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
