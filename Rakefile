require 'cocaine'
require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'sequel'
require 'socket'

task default: [:test, :rubocop]

RSpec::Core::RakeTask.new(:test)

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end

task :environment do
  ENV['RACK_ENV'] ||= 'development'
  puts "loading RACK_ENV=#{ENV['RACK_ENV']}..."
  require File.expand_path('./config/env.rb')
end

#
# Database tasks
#
namespace :db do
  desc 'Wait for postgres'
  task wait: [:environment] do
    puts "wait for #{DB_HOST}:#{DB_PORT}..."
    timeout = 0.5
    5.times do
      begin
        Socket.tcp(DB_HOST, DB_PORT, connect_timeout: 5) {}
        puts 'wait success'
        break
      rescue => e
        puts "wait failed, sleeping for #{timeout} (#{e})"
        sleep(timeout)
        timeout *= 2
      end
    end
  end

  desc 'Create database'
  task create: [:environment, 'db:wait'] do
    line = Cocaine::CommandLine.new(
      "PGPASSWORD=#{ENV['DB_PASSWORD']} createdb",
      ':database -h :host -p :port -U :username'
    )
    line.run(database: DB_NAME,
             host:     DB_HOST,
             port:     DB_PORT.to_s,
             username: DB_USER)
  end

  desc 'Drop database'
  task drop: [:environment, 'db:wait'] do
    line = Cocaine::CommandLine.new(
      "PGPASSWORD=#{ENV['DB_PASSWORD']} dropdb",
      '--if-exists :database -h :host -p :port -U :username'
    )
    line.run(database: DB_NAME,
             host:     DB_HOST,
             port:     DB_PORT.to_s,
             username: DB_USER)
  end

  desc "Dump database schema to 'db/schema.sql'"
  task dump: [:environment, 'db:wait'] do
    line = Cocaine::CommandLine.new('pg_dump', '-s :database -h :host -p :port --role :username -U :username -f :file')
    line.run(database: DB_NAME,
             host:     DB_HOST,
             port:     DB_PORT.to_s,
             username: DB_USER,
             file:     './db/schema.sql')
  end

  desc "Load database from schema 'db/schema.sql'"
  task load: [:drop, :create] do
    line = Cocaine::CommandLine.new('psql', ':database -h :host -p :port -U :username -f :file')
    line.run(database: DB_NAME,
             host:     DB_HOST,
             port:     DB_PORT.to_s,
             username: DB_USER,
             file:     './db/schema.sql')
  end
end
