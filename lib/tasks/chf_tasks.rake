require_dependency Rails.root.join('lib','chf','reports','metadata_completion_report')

namespace :chf do

  desc 'Rough count metadata completion'
  task metadata_report: :environment do
    report = CHF::Reports::MetadataCompletionReport.new
    report.run
    path = File.path("/var/sufia/reports/metadata/")
    FileUtils.mkdir_p(path) unless File.exists?(path)
    fn = "completion-#{Date.today.strftime('%Y-%m-%d')}.txt"
    File.open(File.join(path, fn), 'w') do |f|
      f.write(report.get_output)
      f.write("\n")
    end
  end

  desc 'Re-generate all derivatives'
  task create_derivatives: :environment do
    total = Sufia.primary_work_type.count
    i = 0
    Sufia.primary_work_type.all.find_each do |work|
      i += 1
      puts "Generating derivatives for #{work.id}, work #{i} of #{total}: #{work.title.first}"
      work.file_sets.each do |fs|
        fs.files.each do |file|
          filename = CurationConcerns::WorkingDirectory.find_or_retrieve(file.id, fs.id)
          fs.create_derivatives(filename)
        end
      end
    end
  end

  desc 'Migrate titles and merge descriptions'
  task single_value_migration: :environment do
    CHF::Metadata::SingleValueMigration.run
    puts 'migration complete'
  end

  desc 'Reindex everything'
  # @example RAILS_ENV=production bundle exec rake avalon:reindex would do a single threaded production environment reindex
  # @example RAILS_ENV=production bundle exec rake avalon:reindex[2] would do a dual threaded production environment reindex
  task :reindex, [:threads] => :environment do |t, args|
    descendants = ActiveFedora::Base.descendant_uris(ActiveFedora.fedora.base_uri)
    descendants.shift # remove the root
    Parallel.map(descendants, in_threads: args[:threads].to_i || 1) do |uri|
      begin
        ActiveFedora::Base.find(ActiveFedora::Base.uri_to_id(uri)).update_index
        puts "#{uri} reindexed"
      rescue
        puts "Error reindexing #{uri}"
      end
    end
  end
end
