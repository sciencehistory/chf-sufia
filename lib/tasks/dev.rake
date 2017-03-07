require 'rspec/core'
require 'rspec/core/rake_task'
require 'solr_wrapper'
require 'fcrepo_wrapper'
require 'active_fedora/rake_support'

namespace :dev do
  # Starts Fedora and Solr, per config in `./config/solr_wrapper_test.rb` and
  # and `./config/fcrepo_wrapper_test.rb`. You can still run individual files
  # and line numbers, with:
  #
  #    SPEC=spec/models/users_spec.rb:30 ./bin/rake chf:spec_with_app_load
  #
  # or even multiple ones.... not sure.
  #
  # Used for travis.
  # Based on similar in sufia.
  desc 'Spin up test servers and run specs'
  task :spec_with_app_load  do
    with_test_server do
      Rake::Task['spec'].invoke
    end
  end

  # Believe it or not, there was no built-in sufia stack task
  # that would spin up just fedora and solr but not rails in dev.
  # I wanted it. You can use this in dev or test, it will use
  # appropriate fcrepo_wrapper and solr_wrapper configs depending
  # on environment.
  #
  #      ./bin/rake dev:servers
  #      RAILS_ENV=test ./bin/rake dev:servers
  #
  # Note that in developemnt env config is taken from `.solr_wrapper` and
  # `.fcrepo_wrapper` but in test env, from `./config/solr_wrapper_test.yml`
  # and `./config/fcrepo_wrapper_test.yml`, cause that's hydra stack conventions
  # for some reason.
  #
  # Based on code at https://github.com/projecthydra/hydra-head/blob/b5c92ec8bee49f1788637caf23df8ab599922084/hydra-core/lib/tasks/hydra.rake#L9
  desc 'spin up fedora and solr (not rails)'
  task :servers do
    with_server(ENV['RAILS_ENV'] || 'development') do
      begin
        sleep
      rescue Interrupt
        puts "Stopping server"
      end
    end
  end
end



