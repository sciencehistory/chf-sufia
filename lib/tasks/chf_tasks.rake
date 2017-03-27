require_dependency Rails.root.join('lib','chf','reports','metadata_completion_report')

namespace :chf do

  desc 'Rough count metadata completion'
  task metadata_report: :environment do
    report = CHF::Reports::MetadataCompletionReport.new
    report.run
    path = File.path("/var/sufia/reports/metadata/")
    FileUtils.mkdir_p(path) unless File.exists?(path)
    fn = "completion-#{Date.today.strftime('%Y-%m-%d-%T')}.txt"
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
  task reindex: :environment do
    CHF::Indexer.new.reindex_everything(progress_bar: true, final_commit: true)
  end

  desc 'report translated titles'
  task translated: :environment do
    reporter = CHF::Metadata::TranslatedTitleUpdate.new
    reporter.run
    reporter.matches.each do |id, line|
      puts "#{id}:"
      line.each do |key, val|
        puts "  #{key}: #{val}"
      end
    end
    puts "total: #{reporter.matches.size}"
  end

  desc 'Reindex all GenericWorks'
  task reindex_works: :environment do
    # Like :reindex, but only GenericWorks, makes it faster,
    # plus let's us use other solr techniques to make it faster,
    # and allows us to add a progress bar easily.

    add_batch_size = ENV['ADD_BATCH_SIZE'] || 50

    progress_bar = ProgressBar.create(:total => GenericWork.count, format: "%t: |%B| %p%% %e")
    solr_service_conn = ActiveFedora::SolrService.instance.conn
    batch = []

    GenericWork.find_each do |work|
      batch << work.to_solr

      if batch.count % add_batch_size == 0
        solr_service_conn.add(batch, softCommit: true, commit: false)
        batch.clear
      end
      progress_bar.increment
    end
    if batch.present?
      solr_service_conn.add(batch, softCommit: true, commit: false)
      batch.clear
    end
    $stderr.puts "Issuing a solr commit..."
    solr_service_conn.commit

    $stderr.puts 'reindex_works complete'
  end

  desc 'csv report of related_urls'
  task :related_url_csv, [:output_path] => :environment do |t, args|
    output = args[:output_path] || "related_urls.csv"
    CHF::Metadata::RelatedUrlReport.new.to_csv(output)
  end
end
