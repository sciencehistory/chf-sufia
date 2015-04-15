# README

## Set up a dev environment
* Create workspace directory
* Clone this repo
* Also clone the (currently private) ansible repo
* Install virtualbox and vagrant
* cd into your clone of this repo and run 'vagrant up'

## Run Tests
rake jetty:start
bundle exec rspec
#TODO: bundle exec rake db:migrate RAILS_ENV=test

## Deploy
I'll let you know once I've done it.

## The following are specified by ansible
* Ruby version
* System dependencies
* Configuration
* Database creation
* Database initialization
* Services (job queues, cache servers, search engines, etc.)
