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
    class Static < Evita::Handler
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
      }

      def asset_path
        Robot.config.static && Robot.config.static.not_nil!.asset_path
      end

      def evaluate(msg)
        ppl = @pipeline
        if will_handle?(msg)
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

      def will_handle?(msg)
        can_handle?(msg) && authorized_to_handle?(msg)
      end

      def authorized_to_handle?(msg)
        msg.parameters["from"]? == "wyhaines"
      end

      def can_handle?(msg)
        cmd = command(msg)
        cmd && (Data.has_key?(cmd) || asset_exists?(cmd))
      end

      def asset_exists?(cmd)
        if asset_path && cmd
          File.exists?(File.expand_path(File.join(asset_path.as(String), cmd)))
        else
          false
        end
      end

      def command(msg)
        match = /^\s*!\s*(\w+)/.match(msg.body.join)
        puts "#{msg.body.join} -- #{match.inspect}"
        match && match[1]
      end

      def handle(msg)
        cmd = command(msg)

        reply = ""
        if Data.has_key?(cmd)
          reply = Data[cmd]
        elsif asset_exists?(cmd) && asset_path && cmd
          reply = File.read(File.expand_path(File.join(asset_path.as(String), cmd))) if asset_path
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
