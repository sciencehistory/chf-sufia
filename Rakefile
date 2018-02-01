# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

require 'solr_wrapper/rake_task' unless Rails.env.production?

# Make sure we have CHF::Env even if running tasks without :environment dependency.
# If we didn't have ./lib auto-loading, this could/woudl be just `require`
require_dependency "chf/env"

