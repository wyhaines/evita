module Evita
  class Robot
    getter bus : Bus

    def initialize
      @bus = Bus.new
      @handlers = Array(Handler).new
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
    end

    def register_handler(handler : Handler)
      pipeline = @bus.subscribe(
        tags: ["handler", handler.class.name]
      )
      @handlers << handler

      pipeline
    end

    def register_adapter(adapter : Adapter)
    end
  end
end
