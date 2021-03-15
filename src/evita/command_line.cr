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

          opts.on("-c", "--config CONFFILE", "The configuration file to read.") do |conf|
            config = Config.from_yaml(File.read(conf))
          end
          opts.on("-n", "--name [NAME]", "The port to receive connections on.") do |port|
            config.name = name
          end
          opts.on("-d", "--database [CONNECT_STRING]", "The connection string to use to connect to the robot's database.") do |str|
            config.database = str
          end
        end
        opts.on("--help", "Show this help") do
          puts opts
          exit
        end
        opts.on("-v", "--version", "Show the current version of StreamServer.") do
          puts "#{VERSION_STRING}"
          exit
        end
        opts.invalid_option do |flag|
          STDERR.puts "Error: #{flag} is not a valid option."
          STDERR.puts opts
          exit(1)
        end
      end.parse

      config.mode = mode

      config
    end
  end
end
