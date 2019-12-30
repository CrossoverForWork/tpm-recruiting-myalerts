ENV['RACK_ENV'] ||= 'development'
require 'json'
require 'time'
require 'date'
require 'aws-sdk'
require 'logger'
require 'sequel'
require 'sinatra/base'
require 'trackif_microservices'
require 'log-streamer'
require 'bundler'
require 'mongo' # needed to alter mongo logging in trackif-models
require 'active_support'

require File.expand_path('../env.rb', __FILE__)

# Module for application specific code.
module Service
  NAME = EB_APP_NAME
  VERSION = '3.13.9'.freeze
  IP = '0.0.0.0'.freeze
  LoggerConsole = Logger.new(STDOUT)
  LoggerDb = Logger.new(STDOUT)
  CACHE_STORE = ::ActiveSupport::Cache.lookup_store(:memory_store)
  StreamLoggers::SimpleLogger.adapter = :fluent
  LogStreamer.adapter = :fluent
  FluentLogger = StreamLoggers::SimpleLogger.new(default_hash: {
    application_name: 'alerts-generator-wrk'
  })
end

Service::LoggerConsole.level = case LOGGER_LEVEL
                               when 'debug'
                                 Logger::DEBUG
                               when 'info'
                                 Logger::INFO
                               when 'warn'
                                 Logger::WARN
                               when 'error'
                                 Logger::ERROR
                               when 'fatal'
                                 Logger::FATAL
                               else
                                 Logger::INFO
                               end

Service::LoggerDb.level = case DB_LOG
                          when 'debug'
                            Logger::DEBUG
                          when 'info'
                            Logger::INFO
                          when 'warn'
                            Logger::WARN
                          when 'error'
                            Logger::ERROR
                          when 'fatal'
                            Logger::FATAL
                          else
                            Logger::FATAL
                          end

Mongo::Logger.logger = Service::LoggerDb

require_relative './database'

# should be after database config because of trackif-models
Bundler.require :default, ENV['RACK_ENV']

# Trackif::Json::Schema
if SCHEMA_VALIDATION_ENABLED
  Trackif::Json::Schema.configure do |config|
    config.service = 'alerts-generator-wrk'
    config.version = 'v3'
  end
end

$stdout.sync = true if ENV['RACK_ENV'] == 'development'

# Load files.
files = []
files << File.expand_path('../../lib/*.rb', __FILE__)
files << File.expand_path('../../services/**/*.rb', __FILE__)
Dir[*files].each do |file|
  require file
end

Service::LoggerConsole.formatter = Helpers::MyaLogFormatter.new
