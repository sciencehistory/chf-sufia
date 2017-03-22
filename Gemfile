source 'https://rubygems.org'

# sufia stuff!
#gem 'sufia', '7.2.0'
gem 'sufia', git: 'https://github.com/projecthydra/sufia', branch: '7.2-migration'
gem 'kaminari_route_prefix'
gem 'rsolr', '~> 1.0'

# required for sufia 7.2
gem 'flipflop', git: 'https://github.com/jcoyne/flipflop.git', branch: 'hydra'
# pull in carolyn's charactizejob / derivatives job fix
gem 'curation_concerns', github: 'projecthydra/curation_concerns', branch: '1-6-stable'
# pull in fix to "add another" label
gem 'hydra-editor', github: 'projecthydra/hydra-editor', ref: 'c1e9d298'

# used in some rake tasks, some of which we may want ot run on production.
gem 'ruby-progressbar', '~> 1.0'

# Needed to fix reindex_everything
# But don't go to 11 without being ready for rdf2
gem 'active-fedora', '~>10.3'

# Preserve order
gem 'rdf', '~> 1.99'

# Lock this to fix FAST until post-10.2 release is cut
gem 'qa', git: 'https://github.com/projecthydra-labs/questioning_authority.git', ref: 'baf581f17bdd8470176514c8f48467d5932833e0'

# extras
gem 'hydra-role-management'
gem 'highline'
gem 'rest-client'
gem 'whenever'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 4.2.6'
gem 'devise'
gem 'devise-guests', '~> 0.3'
gem 'resque-pool'

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

group :production do
  gem 'pg'
  gem 'therubyracer', platforms: :ruby
end

group :development, :production do
  gem 'capistrano', '3.4.0'
  gem 'capistrano-bundler', '1.1.4'
  gem 'capistrano-passenger', '0.1.0'
  gem 'capistrano-rails', '1.1.3'
  gem 'capistrano-maintenance', '~> 1.0', require: false
  gem 'capistrano-rake', require: false
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
  gem "factory_girl_rails", "~> 4.4", '>= 4.4.1'
  gem 'jettywrapper'
  gem 'pry'
  gem 'pry-rails'
  gem 'equivalent-xml'
  ## debugging
  #gem 'httplog'
end

group :test do
  gem 'capybara', '~> 2.4'
  gem 'database_cleaner', '~> 1.3'
  gem 'poltergeist', '~> 1.5'
  gem 'jasmine', '~> 2.3'
  gem 'rspec-activemodel-mocks'
  gem 'webmock'
  gem 'phantomjs', '~> 2.1.1'
  gem 'capybara-screenshot'
end

group :development, :test do
  gem 'solr_wrapper', '>= 0.3'
end

group :development, :test do
  gem 'fcrepo_wrapper'
end
