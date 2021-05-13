module Evita
  module Handlers
    class Echo < Evita::Handler
      def handle(msg)
        msg.reply(body: "#{@handle_counter.get}: #{msg.body.join}")
      end
    end
  end
end
