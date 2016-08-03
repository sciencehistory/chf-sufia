require_dependency Rails.root.join('lib','chf','reports','metadata_completion_report')

namespace :chf do

  desc 'Re-generate all derivatives'
  task create_derivatives: :environment do
    total = GenericFile.count
    i = 0
    GenericFile.all.find_each do |f|
      i += 1
      puts "Generating derivatives for #{f.id}, file #{i} of #{total}: #{f.title.first}"
      f.create_derivatives
      f.save
    end
  end

  desc 'Rough count metadata completion'
  task metadata_report: :environment do
    report = CHF::Reports::MetadataCompletionReport.new
    report.run
    report.write
  end

end
