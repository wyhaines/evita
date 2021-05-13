module Evita
  abstract class Handler < Bus::Handler
    getter bot : Evita::Robot

    def initialize(@bot : Robot,
                   @bus : Bus? = nil,
                   tags : Array(String) = [] of String,
                   @force = nil)
      super(
        bus: @bus,
        tags: tags,
        force: @force
      )
      @pipeline = @bot.register_handler(self)
    end
  end
end

require "./handlers/*"
