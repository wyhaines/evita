require "twitch_event_sub"

module Evita
  module Handlers
    # Twitch supports an EventSub API that is used to subscribe
    # to a variety of notification types. This handler lets the
    # chatbot subscribe to events via configuration or via commands
    # and to respond to those events.
    #
    # Event responses can be a static text response, a templated
    # response, a response powered with GPT-3, or the result of
    # running some external code.
    #
    # Interactive commands are:
    # !twitch:subscribe
    # !twitch:list_subscriptions
    # !twitch:unsubscribe
    class TwitchEventSub < Handler
      class Config
        include YAML::Serializable
        include YAML::Serializable::Unmapped

        @[YAML::Field(key: "asset_path", emit_null: true)]
        getter asset_path : String? = nil
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

end
