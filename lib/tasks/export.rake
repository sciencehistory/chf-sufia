# bundle exec rake chf:export
require 'fileutils'
require 'byebug'

namespace :chf do
  desc """Export all Collections, GenericWorks and FileSets to JSON files.
  JSON files are written to tmp/export, whose contents are first deleted.
  To import into scihist_digicoll: move the contents of tmp/export and to a corresponding
  scihist_digicoll/tmp/import directory, then run `bundle exec rake scihist_digicoll:import`.
  """
  task :export => :environment do
    the_classes = %w(FileSet GenericWork Collection)

    total_tasks = the_classes.sum { |x| x.constantize.count }
    progress_bar = ProgressBar.create(total: total_tasks, format: "%a %t: |%B| %R/s %c/%u %p%% %e")

    export_dir = Rails.root.join('tmp', 'export')
    FileUtils.rm_rf(export_dir)
    Dir.mkdir(export_dir)
    the_classes.each do |s|
      progress_bar.log("INFO: Exporting #{s}s")
      exporter_class = "#{s}Exporter".constantize
      exportee_class = exporter_class.exportee
      dir = Rails.root.join('tmp', 'export', exporter_class.dirname)
      Dir.mkdir(dir)
      exportee_class.find_each do |x|
        exporter_class.new(x).write_to_file()
        progress_bar.increment
      end
    end # exporters.each
  end # task
end # namespace
