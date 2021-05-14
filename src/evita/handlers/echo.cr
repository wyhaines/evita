module Evita
  module Handlers
    # This handler primarily exists for testing purposes. Its only purpose
    # is to echo whatever message that it gets back to the original sender,
    # with the addition of a counter to show how many messages it has
    # handled.
    class Echo < Evita::Handler
      def handle(msg)
        msg.reply(body: "#{@handle_counter.get}: #{msg.body.join}")
      end
    end
  end
end
