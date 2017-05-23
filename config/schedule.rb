# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

env :PATH, ENV['PATH']

every 1.month do
  rake "chf:metadata_report"
end

every 1.day, :at => '2:30 am' do
  rake "chf:fixity_checks"
end
