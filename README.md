# README

## Description
The Sufia-based application powering CHF's digital collections site. CHF's digitical collections team is currently hard at work ingesting content before making the site publicly available!

## Dependencies
All system setup for development and production machines is managed and documented via ansible playbooks that use the roles defined in https://github.com/curationexperts/ansible-hydra.

## Deployment
bundle exec cap deploy [target machine]

## Run Tests
bundle exec rspec

## Run tests continuously using Guard
bundle exec guard -p -l 10
