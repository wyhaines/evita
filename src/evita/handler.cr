require "./pipeline"

module Evita
  abstract class Handler
    @pipeline : Evita::Pipeline(Evita::Message)?
    @listener_proc : Fiber? = nil
    getter bot : Evita::Robot

    def initialize(@bot : Robot)
      @handle_counter = 0_u64
      @evaluate_counter = 0_u64
      @pipeline = @bot.register_handler(self)
      @listener_proc = nil
    end

    def run
      @listener_proc = listen
    end

    # This should spawn a fiber that will listen to the message bus for
    # messages intended for the handler.

    abstract def evaluate(msg)
    abstract def handle(msg)

    def will_handle?(msg)
      can_handle?(msg) && authorized_to_handle?(msg)
    end

    # This should probably be overridden in subclasses so that they can make
    # informed decisions about whether or not they can handle the message.
    def can_handle?(msg)
      true
    end

    # Override this if only certain users should be authorized to have access
    # to the given handler.
    def authorized_to_handle?(msg)
      true
    end

    def listen
      spawn(name: "Generic Handler Listen Loop") do
        ppl = @pipeline
        loop do
          begin
            msg = ppl.receive if !ppl.nil?
            if !msg.nil?
              if msg.evaluated
                @handle_counter += 1
                handle(msg)
              else
                @evaluate_counter += 1
                evaluate(msg)
              end
            end
          rescue e : Exception
            puts "#{e}\n\n#{e.backtrace.join("\n")}" # TODO: Better exception logging
          end
        end
      end
    end
  end
end

require "./handlers/*"
