require "db"
require "sqlite3"
require "./bus"
require "./command_line"
require "./database"

module Evita
  @@bot : Robot
  class_property! bot : Robot

  class Robot
    @db : DB::Database
    @config : Config
    @@config : Evita::Config = CommandLine.parse_options

    getter bus : Bus
    getter db : DB::Database
    property name : String = "Evita"
    getter config : Config

    def self.set_config(config)
      @@config = config
    end

    def self.config
      @@config
    end

    def initialize
      @config = @@config
      puts @config.inspect
      Robot.set_config(@config)
      @db = Database.setup(@config)
      @bus = Bus.new
      @handlers = Array(Handler).new
      @adapters = Array(Adapter).new
      Evita.bot = self
    end

    def health_check
      # TODO: Placeholder, but should probably do something someday.
    end

    def send(message : Message)
      @bus.send(message)
    end

    def subscribe(tags : Array(String))
      @bus.subscribe(tags)
    end

    def message(
      body : String,
      origin : String? = nil,
      parameters : Hash(String, String) = Hash(String, String).new
    )
      @bus.message(
        body: body,
        origin: origin,
        parameters: parameters,
        tags: ["handler"]
      )
    end

    def register_handler(handler : Handler) : Pipeline(Message)
      pipeline = @bus.subscribe(
        tags: ["handler", "handler:#{handler.class.name}"]
      )
      @handlers << handler

      pipeline
    end

    def register_adapter(adapter : Adapter) : Pipeline(Message)
      pipeline = @bus.subscribe(
        tags: ["adapter", "adapter:#{adapter.class.name}"]
      )
      @adapters << adapter

      pipeline
    end
  end
end
