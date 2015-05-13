# This file is copied to spec/ when you run 'rails generate rspec:install'
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
require 'spec_helper'
require 'rspec/rails'

# Add additional requires below this line. Rails is not loaded until this point!
require 'capybara/rspec'
require 'capybara/poltergeist'
require 'database_cleaner'
require 'active_fedora/cleaner'
require 'devise'
require 'support/features'
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

Capybara.default_driver = :rack_test      # This is a faster driver
Capybara.javascript_driver = :poltergeist # This is slower

RSpec.configure do |config|
  config.include Warden::Test::Helpers, type: :feature
  config.include Devise::TestHelpers, type: :controller
  config.after(:each, type: :feature) { Warden.test_reset! }

  config.before :each do |example|
    if example.metadata[:type] == :feature && Capybara.current_driver != :rack_test
      DatabaseCleaner.strategy = :truncation
    else
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.start
    end

    ActiveFedora::Cleaner.clean!
  end
  config.after do
    DatabaseCleaner.clean
  end

  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!
end
