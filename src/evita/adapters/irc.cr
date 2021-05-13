require "simple_irc"

module Evita
  module Adapters
    class Irc < Adapter
      getter client : SimpleIrc::Client

      PREAMBLE_MARKER = /You are in a maze of twisty passages, all alike./

      def initialize(@bot)
        super
        @discard_preamble = true
        @client = SimpleIrc::Client.new(
          token: "",
          nick: "",
          channel: "",
          do_connect: false
        )
        @user = User.new(adapter: self, name: "Shell User")
      end

      def origin
        @pipeline.is_a?(Bus::Pipeline) ? @pipeline.origin : nil
      end

      def service
        "irc"
      end

      def namespace
        "irc"
      end

      def roster(room)
        [user]
      end

      def run
        join
        @output_proc = spawn(name: "receive_output for #{self.class}:#{@user.name}") do
          receive_output
        rescue e : Exception
          puts "output_proc: #{e}"
        end
        @input_proc = spawn(name: "receive_input for #{self.class}:#{@user.name}") do
          receive_input
        rescue e : Exception
          puts "input_proc: #{e} == #{e.backtrace.join("\n")}"
        end
      end

      def join
        @client = SimpleIrc::Client.new(
          host: "irc.chat.twitch.tv",
          token: ENV["TWITCH_EVITA_TOKEN"],
          port: 6697,
          ssl: true,
          channel: ENV["TWITCH_EVITA_CHANNEL"],
          nick: ENV["TWITCH_EVITA_NICK"]? || "Evita"
        )
        @client.authenticate
        @client.join
        @client.privmsg("Hi. I am #{@bot.name}.")
      end

      def part; end

      def set_topic(topic : String)
      end

      def shut_down
        @client.quit
      end

      def receive_output
        loop do
          msg = @pipeline.receive
          send_output(msg.body)
        end
      rescue e : Exception
        puts "BOOM! #{e} -- #{e.backtrace.join}"
      ensure
        puts "exit receive output"
      end

      def send_output(strings : Array(String), target : String? = nil)
        strings.reject!(&.empty?)

        @client.privmsg strings.join("\n")
      end

      def shut_down
        puts
      end

      def read_input : String?
        b = @bot
        return if b.nil?
        raw_input = @client.gets
        if @discard_preamble
          @discard_preamble = false if raw_input =~ PREAMBLE_MARKER
          nil
        else
          raw_input
        end
      end

      def ping?(input)
        input =~ /PING\s+:tmi.twitch.tv/
      end

      def pong
        @client.direct "PONG :tmi.twitch.tv"
      end

      def normalize_bot_name(txt)
        txt.gsub(/\@?(#{@bot.name}|#{ENV["TWITCH_EVITA_NICK"]})\s*:?\s*/i, @bot.name)
      end

      def receive_input
        loop do
          begin
            # NRApp.app.non_web_transaction("input") do |txn|
            input = ""
            # txn.segment("Read Input") do |segment|
            input = read_input
            # end
            if input.nil?
              puts "Nil input"
            elsif ping?(input)
              puts input
              pong
            else
              b = @bot

              matches = input.not_nil!.match(/^:(?<username>.+)!.+ PRIVMSG #\w+ :(?<txt>.+)$/)

              if !b.nil? && matches
                username = matches["username"]
                txt = normalize_bot_name(matches["txt"])

                puts input
                msg = b.message(
                  body: txt,
                  origin: origin,
                  parameters: {"from" => username}
                )

                b.health_check

                b.send(
                  msg
                )
              else
                puts input
              end
            end
            # Fiber.yield
            # end
          rescue e : Exception
            puts e
          end
        end
      end
    end
  end
end
