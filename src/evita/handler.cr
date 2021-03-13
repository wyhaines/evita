require "./pipeline"

module Evita
  abstract class Handler
    @pipeline : Evita::Pipeline(Evita::Message)?
    @listener_proc : Fiber? = nil

    def initialize(@bot : Robot)
      @pipeline = @bot.register_handler(self)
      @listener_proc = nil
    end

    def run
      @listener_proc = listen
    end

    abstract def listen
  end
end

require "./handlers/*"