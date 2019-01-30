# bundle exec rake chf:export
require 'fileutils'
namespace :chf do
  desc "Export the entire collection to JSON files"
  task :export => :environment do


    to_do = {'Collection'=> [], 'GenericWork'=> [], 'FileSet' => []}
    collection_ids = ENV['ONLY_COLLECTIONS'].split(",") if ENV['ONLY_COLLECTIONS']

    collection_ids.uniq!
    collection_ids.sort!

    if collection_ids.nil?
      to_do = nil
    else
      collection_ids.each do |c_id|
        coll = Collection.find(c_id)
        to_do['Collection'] << c_id
        coll.members.to_a.map(&:id).each do | gw_1_id |
          gw_1 = GenericWork.find(gw_1_id)
          to_do['GenericWork'] << gw_1_id
          gw_1.ordered_members.to_a.map(&:id).each do | m_1_id |
            begin
              gw_1 = GenericWork.find(m_1_id)
              to_do['GenericWork'] << m_1_id
              gw_1.ordered_members.to_a.map(&:id).each do | m_2_id |
                begin
                  gw_2 = GenericWork.find(m_2_id)
                  to_do['GenericWork'] << m_2_id
                rescue ActiveFedora::ActiveFedoraError
                  to_do['FileSet'] << m_2_id
                end # rescue m_2 was a fileset
              end  #each m_2_id
            rescue ActiveFedora::ActiveFedoraError
              to_do['FileSet'] << m_1_id
            end # rescue m_1 was a fileset
          end  # each m_1_id
        end # each collection member
      end # each collection

      to_do['GenericWork'].uniq!
      to_do['GenericWork'].sort!
      to_do['FileSet'].uniq!
      to_do['FileSet'].sort!

      puts "Collections:  #{collection_ids.count}"
      puts "GenericWorks: #{to_do['GenericWork'].count}"
      puts "FileSets:     #{to_do['FileSet'].count}"
      puts "To proceed with the export, type yes"
      answer = STDIN.gets.strip
      exit unless answer == 'yes'

    end # if we are traversing collections


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
        unless to_do.nil?
          next unless to_do[s].include? item.id
        end
        exporter_class.new(item).write_to_file()
      end
    end # exporters.each
  end # task
end # namespace