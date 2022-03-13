require "rubygems"
require "bundler/setup"

require "sqlite3"
require "active_record"
require "yaml"
require "./lib/database_connector"

include ActiveRecord::Tasks

DatabaseTasks.env = DatabaseConnector.env
DatabaseTasks.database_configuration = DatabaseConnector.configurations
DatabaseTasks.root = File.dirname(__FILE__)
DatabaseTasks.db_dir = "db"
DatabaseTasks.migrations_paths = "db/migrate"

task :environment do
  DatabaseConnector.establish_connection
end

load "active_record/railties/databases.rake"
