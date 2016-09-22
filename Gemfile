source 'https://rubygems.org'

# lock for migration; update to 6.x-stable
gem 'rdf', '1.99'
gem 'blacklight-gallery', '0.4.0' # after this it depends on blacklight 6 which is giving bundler problems
gem 'deprecation', '0.1' # not sure why this is a problem...
gem 'google_drive', '1.0.6'
#gem 'rdf-tabular', '0.3'
#gem 'active-fedora', '9.8.2'
#gem 'active-triples', '0.7.4'
gem 'blacklight', '5.16.4' # updating this broke metadata form

# sufia stuff!
#gem 'sufia', '6.5.0'
#gem 'sufia', '6.6.0'
gem 'sufia', github: 'projecthydra/sufia', branch: '6.x-stable'
gem 'kaminari', github: 'jcoyne/kaminari', branch: 'sufia'
gem 'rsolr', '~> 1.0.6'

# extras
gem 'hydra-role-management'
gem 'rdf-vocab'
gem 'hydra-editor', github: 'projecthydra/hydra-editor', :ref => '7c8983'
gem 'qa', github: 'projecthydra-labs/questioning_authority'
# TODO it should be fine to remove this if PR #1326
# is accepted into sufia
gem 'posix-spawn'
gem 'highline'

# local upgrades!
gem 'ldp', '~> 0.4.0'
# need fix in noid 1.0.3
gem 'active_fedora-noid', '~> 1.0', '>= 1.0.3'
# need fix from 9.6.0
#gem 'active-fedora', '~> 9.0', '>= 9.6.0'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.6'
# Use sqlite3 as the database for Active Record
# moved sqlite gem to development section
# gem 'sqlite3'
group :production do
  gem 'pg'
end
gem 'therubyracer', platforms: :ruby

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'devise'
gem 'devise-guests', '~> 0.3'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
group :development do
  gem 'capistrano', '3.4.0'
  gem 'capistrano-bundler', '1.1.4'
  gem 'capistrano-passenger', '0.1.0'
  gem 'capistrano-rails', '1.1.3'
  gem 'capistrano-maintenance', '~> 1.0', require: false
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'pry-byebug'
  gem 'sqlite3'
  # Access an IRB console on exception pages or by using <%= console %> in views
  #gem 'web-console', '~> 2.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'guard-rspec'
  gem 'spring-commands-rspec', '~> 1.0.2'

  gem 'rspec-rails', '~> 3.1'
  gem "factory_girl_rails", "~> 4.4.1"
  gem 'jettywrapper'
  gem 'pry'
  gem 'pry-rails'
end

group :test do
  gem 'capybara', '~> 2.4'
  gem 'database_cleaner', '~> 1.3'
  gem 'poltergeist', '~> 1.5'
  gem 'jasmine', '~> 2.3'
  gem 'rspec-activemodel-mocks'
  gem 'webmock'
end
