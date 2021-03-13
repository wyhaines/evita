module Evita
  module Handlers
    class Echo < Handler
      def listen
        spawn {
          counter = 0
          ppl = @pipeline
          loop do
            msg = ppl.receive if !ppl.nil?
            if !msg.nil?
              counter += 1
              msg.reply(body: "#{counter}: #{msg.body.join}")
            end
          end
        }
      end
    end
  end
end
