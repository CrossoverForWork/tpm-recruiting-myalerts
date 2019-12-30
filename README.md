## Alerts Generator Wrk

## Setting up dev environment.

* `docker-compose build`
* `docker-compose run --rm worker bash`
* `bundle exec rake db:load`

## Running tests

To run using docker: 

* `docker-compose up test`

To run from container:

* `docker-compose build`
* `docker-compose run --rm worker bash`
* `RACK_ENV=test bundle exec rake db:load`
* `bundle exec rake` or `bundle exec rspec -e 'specific tests'`
