require "./bus"

module Evita
  class Robot
    getter bus : Bus
    property name : String = "Evita"

    def initialize
      @bus = Bus.new
      @handlers = Array(Handler).new
      @adapters = Array(Adapter).new
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
