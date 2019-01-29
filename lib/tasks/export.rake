# bundle exec rake chf:export
require 'fileutils'
namespace :chf do
  desc "Export the entire collection to JSON files"
  task :export => :environment do
    the_classes = %w(FileSet GenericWork Collection)
    export_dir = Rails.root.join('tmp', 'export')
    FileUtils.rm_rf(export_dir)
    Dir.mkdir(export_dir)
    the_classes.each do |s|
      exporter_class = "#{s}Exporter".constantize
      exportee_class = exporter_class.exportee
      dir = Rails.root.join('tmp', 'export', exporter_class.dirname)
      Dir.mkdir(dir)
      exportee_class.find_each() do | item |
        exporter_class.new(item).write_to_file()
      end
    end # exporters.each
  end # task
end # namespace