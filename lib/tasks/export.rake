# bundle exec rake chf:export
require 'fileutils'
namespace :chf do
  desc """Export all Collections, GenericWorks and FileSets to JSON files.
  JSON files are written to tmp/export, whose contents are first deleted.
  Specify ONLY_COLLECTIONS='collection_id' to export only a particular collection and its contents.
  To import into scihist_digicoll: move the contents of tmp/export and to a corresponding
  scihist_digicoll/tmp/import directory, then run `bundle exec rake scihist_digicoll:import`.
  """
  task :export => :environment do

  to_do = {'Collection'=> [], 'GenericWork'=> [], 'FileSet' => []}
  collection_ids = ENV['ONLY_COLLECTIONS'].split(",") if ENV['ONLY_COLLECTIONS']

  if collection_ids.nil?
    to_do = nil
    puts "Export the ENTIRE COLLECTION?"
  else
    collection_ids.uniq!
    collection_ids.sort!
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

    end # if we are traversing collections

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


      items_to_look_up = []
      if to_do.nil?
        exportee_class.find_each {|x| items_to_look_up << x }
      else
        items_to_look_up = to_do[s].collect { |x| exportee_class.find(x) }
      end

      items_to_look_up.each do | item |
        exporter_class.new(item).write_to_file()
      end

    end # exporters.each
  end # task
end # namespace