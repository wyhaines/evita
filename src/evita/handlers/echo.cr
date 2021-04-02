module Evita
  module Handlers
    class Echo < Handler
      def evaluate(msg)
      end

      def handle(msg)
        msg.reply(body: "#{@handle_counter}: #{msg.body.join}")
      end
    end
  end
end
