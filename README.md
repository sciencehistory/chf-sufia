# README

## Description
The Sufia-based application powering CHF's digital collections site. CHF's digitical collections team is currently hard at work ingesting content before making the site publicly available!

## Dependencies
All system setup for development and production machines is managed and documented via ansible playbooks that use the roles defined in https://github.com/curationexperts/ansible-hydra.

## Development

One way to do development might be to set up a ubuntu VM and use the
ansible scripts. But these are instructions for setting it up on an OSX
dev box, without a VM. 

* Dependencies (also check at https://github.com/projecthydra/sufia#prerequisites)
	* `brew install imagemagick`
	* `brew install fits`
	* `brew install redis`
		* `brew services start redis`
	* postgres (on osx, i like https://postgresapp.com/)

* `cp config/secrets.yml.example config/secrets.yml`
	* you will need to fill out some secret sierra connection config in here
* `cp config/blacklight.yml.example config/blacklight.yml`
* `cp config/fedora.yml.example config/fedora.yml`
* `cp config/solr.yml.example config/solr.yml`

* db setup
	* `./bin/rake db:create db:schema:load`

* You need a Fedora instance running and a Solr instance running. Instead of using
ansible (playbooks may not be suitable for your dev machine, unless you make a VM
matching production), you can use the hydra-community-provided wrapper scripts:

       $ fcrepo_wrapper
     
       $ solr_wrapper


## Deployment
bundle exec cap [target machine] deploy

See more at: https://chemheritage.atlassian.net/wiki/spaces/HDCSD/pages/5668869/Deployment+Capistrano

## Run Tests
bundle exec rspec

## Run tests continuously using Guard
bundle exec guard -p -l 10
