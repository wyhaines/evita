module Evita
  module Handlers
    # This handler will volunteer to handle a message if it
    # has a specific response to the message payload that makes
    # sense. i.e. if a message goes out to be handled, with
    # content of "!futurestack", and this handler has been
    # given static content for that message, then it will bid
    # very high in order to answer the message because it has
    # absolute certainty that it has an appropriate response to
    # the message.
    # If it does not have a match, though, it will decline to
    # handle the message at all.
    class Static < Handler
      Data = {
        marco:       "polo",
        ping:        "pong",
        futurestack: "Level up your observability game at FutureStack, a free virtual event May 25-27! https://bit.ly/futurestack-twitch",
      }

      def evaluate(msg)
        ppl = @pipeline
        if can_handle?(msg)
          msg.send_evaluation(
            relevance: 2,
            certainty: 1000000,
            receiver: ppl.origin
          ) if ppl
        else
          msg.send_evaluation(
            relevance: -1000000,
            certainty: -1000000,
            receiver: ppl.origin
          ) if ppl
        end
      end

      def can_handle?(msg)
        cmd = command(msg)
        cmd && Data.has_key?(cmd)
      end

      def command(msg)
        match = /^\s*!\s*(\w+)/.match(msg.body.join)
        match && match[1]
      end

      def handle(msg)
        cmd = command(msg)
        reply = Data[cmd]? if cmd
        msg.reply(body: reply) if reply
      end
    end
  end
end
