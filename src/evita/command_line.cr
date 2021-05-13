require "yaml"
require "option_parser"
require "./config"

module Evita
  class CommandLine
    VERSION_STRING = "Evita v#{Evita::VERSION}"

    def self.parse_options
      config = Config.from_yaml(
        <<-EYAML
        ---
        name: Evita
        database: sqlite3://./evita.db
        EYAML
      )

      mode = "test"

      OptionParser.new do |opts|
        opts.banner = "#{VERSION_STRING}\nUsage: evita [options]"
        opts.separator ""
        opts.on("run", "Run the bot.") do
          mode = "run"

          opts.on("-c", "--config [CONFFILE]", "The configuration file to read.") do |conf|
            config = Config.from_yaml(File.read(conf))
          end
          opts.on("-n", "--name [NAME]", "The name that the bot will use.") do |name|
            set_name(config, name)
          end
          opts.on("-d", "--database [CONNECT_STRING]", "The connection string to use to connect to the robot's database.") do |database|
            set_database(config, database)
          end
          opts.on("-h", "--help", "Show this help") do
            puts get_help(opts)
            exit
          end
          opts.on("-v", "--version", "Show the current version of StreamServer.") do
            puts get_version
            exit
          end
          opts.invalid_option do |flag|
            STDERR.puts "Error: #{flag} is not a valid option."
            STDERR.puts opts
            exit(1)
          end
        end
        opts.on("test", "Test the bot without actually starting it") do
          mode = "test"

          opts.on("-c", "--config [CONFFILE]", "The configuration file to read.") do |conf|
            config = Config.from_yaml(File.read(conf))
          end
          opts.on("-n", "--name [NAME]", "The name that the bot will use.") do |name|
            set_name(config, name)
          end
          opts.on("-d", "--database [CONNECT_STRING]", "The connection string to use to connect to the robot's database.") do |database|
            set_database(config, database)
          end
          opts.on("-h", "--help", "Show this help") do
            config.extra << get_help(opts)
          end
          opts.on("-v", "--version", "Show the current version of StreamServer.") do
            config.extra << get_version
          end
          opts.invalid_option do |flag|
            config.extra << "Error: #{flag} is not a valid option."
          end
        end
      end.parse

      config.mode = mode

      config
    end

    def self.set_name(config, name)
      config.name = name
    end

    def self.set_database(config, database)
      config.database = database
    end

    def self.get_version
      VERSION_STRING
    end

    def self.get_help(opts)
      opts.to_s
    end
  end
end
