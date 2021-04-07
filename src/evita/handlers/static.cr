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
      class Config
        include YAML::Serializable
        include YAML::Serializable::Unmapped

        @[YAML::Field(key: "asset_path", emit_null: true)]
        getter asset_path : String? = nil
      end

      # I don't think that I actually want to take this approach of compiling things in directly.
      #
      # macro from_proc(path)
      #   {% code = read_file?(path) %}
      #   ->() { {{ code.id }} }
      # end

      # macro from_content(path)
      #   {% content = read_file?(path) %}
      #   {{ content.stringify }}
      # end

      # macro dbg(path)
      #   puts path
      # end

      Data = {
        "marco"       => "polo",
        "ping"        => "pong",
        "futurestack" => "Level up your observability game at FutureStack, a free virtual event May 25-27! https://bit.ly/futurestack-twitch",
      })

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

      def authorized_to_handle(msg)
        msg.parameters["from"]? == "wyhaines"
      end

      def command(msg)
        match = /^\s*!\s*(\w+)/.match(msg.body.join)
        match && match[1]
      end

      def handle(msg)
        cmd = command(msg)
        if cmd
          match = Data[cmd]?
          if match && match.is_a?(Proc)
            reply = match.call.to_s
          else
            reply = Data[cmd].as(String)
          end
        end
        msg.reply(body: reply) if reply
      end
    end
  end

  class Config
    @[YAML::Field(key: "static", emit_null: true)]
    getter static : Handlers::Static::Config?
  end
end
