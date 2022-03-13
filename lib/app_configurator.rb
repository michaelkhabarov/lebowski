require "logger"
require "dotenv/load"

require "./lib/database_connector"

class AppConfigurator
  def configure
    setup_database
  end

  def secrets
    YAML.safe_load(IO.read("config/secrets.yml"))
  end

  def token
    ENV["LEBOWSKI_TG_BOT_TOKEN"] || raise("No LEBOWSKI_TG_BOT_TOKEN provided")
  end

  def logger
    AppConfigurator.logger
  end

  def self.logger
    @logger ||= Logger.new($stdout, Logger::DEBUG)
  end

  private

  def setup_database
    DatabaseConnector.establish_connection
  end
end
