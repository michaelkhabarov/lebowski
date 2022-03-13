require "active_record"
require "erb"
require "logger"

class DatabaseConnector
  class << self
    def establish_connection
      ActiveRecord::Base.logger = Logger.new(active_record_logger_path)
      ActiveRecord::Base.configurations = configurations
      ActiveRecord::Base.establish_connection(env.to_sym)
    end

    def env
      ENV["ENV"] || "development"
    end

    def configurations
      YAML.load(ERB.new(File.read(database_config_path)).result)
    end

    private

    def active_record_logger_path
      return $stdout if env == "production"
      "logs/#{env}.log"
    end

    def database_config_path
      "config/database.yml"
    end
  end
end
