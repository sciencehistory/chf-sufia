# README

## Set up a dev environment
* Create workspace directory
* Clone this repo
* Install virtualbox and vagrant
* cd into your clone of this repo and run 'vagrant up'

## Run Tests
vagrant ssh
cd /vagrant
rake jetty:start
bundle exec rspec

## Run tests continuously from vagrant machine using Guard
bundle exec guard -p -l 10

## Deploy
I'll let you know once I've done it.

## The following are specified by ansible
* Ruby version
* System dependencies
* Configuration
* Database creation
* Database initialization
* Services (job queues, cache servers, search engines, etc.)
