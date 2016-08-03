require_dependency Rails.root.join('lib','chf','reports','metadata_completion_report')

namespace :chf do

  desc 'Rough count metadata completion'
  task metadata_report: :environment do
    report = CHF::Reports::MetadataCompletionReport.new
    report.run
    report.write
  end

end
