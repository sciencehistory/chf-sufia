require_dependency Rails.root.join('lib','chf','reports','metadata_completion_report')

namespace :chf do

  desc 'Rough count metadata completion'
  task metadata_report: :environment do
    report = CHF::Reports::MetadataCompletionReport.new
    report.run
    report.write
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
end
