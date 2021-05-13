require "twitch_event_sub"
require "./twitch_event_sub/twitch_event_sub_driver"

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
    class TwitchEventSub < Evita::Handler
      class Config
        include YAML::Serializable
        include YAML::Serializable::Unmapped

        @[YAML::Field(key: "asset_path", emit_null: true)]
        getter asset_path : String? = nil
      end

      def initialize(@bot : Robot)
        super
        @subscriptions = ::TwitchEventSub::Subscriptions.new(
          client_id: ENV["TWITCH_CLIENT_ID"],
          authorization: ENV["TWITCH_APP_ACCESS_TOKEN"],
          handler: Evita::TwitchEventSubDriver
        )
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
        cmd, subscription, arg = command(msg)
        TwitchEventSubDriver.twitch_subscription_handler_commands.includes?(cmd)
      end

      def asset_exists?(cmd)
        if asset_path && cmd
          File.exists?(File.expand_path(File.join(asset_path.as(String), cmd)))
        else
          false
        end
      end

      def command(msg)
        match = /^\s*!\s*(subscribe|unsubscribe|list_subscriptions)\s+([\w\.]+)\s+(.*)/i.match(msg.body.join)
        if match
          {match[1].downcase, match[2].downcase, match[3]}
        else
          {nil, nil, nil}
        end
      end

      def handle(msg)
        cmd, subscription, arg = command(msg)

        reply = case cmd
                when "subscribe"          then handle_subscribe(subscription, arg)
                when "unsubscribe"        then handle_unsubscribe(subscription, arg)
                when "list_subscriptions" then handle_list_subscriptions
                else
                  "I did not understand that command. I can !subscribe, !unsubscribe, or !list_subscriptions."
                end

        msg.reply(body: reply.to_s)
      end

      def handle_subscribe(subscription, arg)
      end

      def handle_unsubscribe(subscription, arg)
      end

      def handle_list_subscriptions
        subscriptions = @subscriptions.list
        subscriptions.data.map do |sub|
          <<-ESUB
          type: #{sub.type}
          id: #{sub.id}
          created at #{sub.created_at}
          status: #{sub.status}
          condition: #{sub.condition.inspect}
          ESUB
        end.join("\n")
      end
    end
  end

  class Config
    @[YAML::Field(key: "twitch_event_sub", emit_null: true)]
    getter static : Handlers::TwitchEventSub::Config?
  end
end
