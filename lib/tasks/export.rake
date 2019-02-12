# bundle exec rake chf:export
require 'fileutils'
namespace :chf do
  desc """Export all Collections, GenericWorks and FileSets to JSON files.
  JSON files are written to tmp/export, whose contents are first deleted.
  To import into scihist_digicoll: move the contents of tmp/export and to a corresponding
  scihist_digicoll/tmp/import directory, then run `bundle exec rake scihist_digicoll:import`.
  """
  task :export => :environment do

    to_do = {'Collection'=> [], 'GenericWork'=> [], 'FileSet' => []}

    puts "To proceed with the export, type yes"
    answer = STDIN.gets.strip
    exit unless answer == 'yes'

    the_classes = %w(FileSet GenericWork Collection)
    export_dir = Rails.root.join('tmp', 'export')
    FileUtils.rm_rf(export_dir)
    Dir.mkdir(export_dir)
    the_classes.each do |s|
      exporter_class = "#{s}Exporter".constantize
      exportee_class = exporter_class.exportee
      dir = Rails.root.join('tmp', 'export', exporter_class.dirname)
      Dir.mkdir(dir)
      exportee_class.find_each do |x|
        exporter_class.new(x).write_to_file()
      end

    end # exporters.each
  end # task
end # namespace