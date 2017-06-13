# Use this file to easily define all of your cron jobs.
# Learn more: http://github.com/javan/whenever

env :PATH, ENV['PATH']

every 1.month, roles: [:app] do
  rake "chf:metadata_report"
end

every 1.day, :at => '2:30 am', roles: [:jobs] do
  rake "chf:fixity_checks"
end

every 1.day, :at => '2:00 am', roles: [:app] do
  rake "blacklight:delete_old_searches[7]"
end
