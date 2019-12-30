require 'simplecov'
SimpleCov.start

ENV['RACK_ENV'] = 'test'
require 'rubygems'
require 'rack/test'
require 'digest/sha1'
require 'allure-rspec'

require_relative '../config/app'

DatabaseCleaner.strategy = :transaction
DatabaseCleaner.clean_with(:truncation)

Dir[File.dirname(__FILE__) + '/factories/**/*.rb'].each { |f| require f }

RSpec.configure do |config|
  config.include AllureRSpec::Adaptor
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end
end
