module Evita
  class Handler
    @pipeline : Evita::Pipeline(Evita::Message)?

    def initialize(@bot : Robot)
      @pipeline = @bot.register_handler(self)
      @listener_proc : Fiber? = nil
    end

    def run
      @listener_proc = listen
    end
  
    abstract def listen
  end
end