require "crirc"

module Evita
  module Adapters
    class Irc < Adapter
      getter client : Crirc::Network::Client?

      def initialize(@bot)
        super
        @client = nil
        @user = User.new(adapter: self, name: "Shell User")
      end

      def origin
        @pipeline.is_a?(Pipeline) ? @pipeline.origin : nil
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

      def receive_input
        loop do
          begin
            message = @client.gets
            next if message.nil?

            b = @bot
            if !b.nil?
              msg = b.message(
                body: message,
                origin: origin,
                parameters: {"from" => @user.name}
              )

              b.send(
                msg
              )
            end
          rescue IO::TimeoutError
            puts "The IRC connection timed out..."
          end
        end
      end

      def send_output(strings : Array(String), target : String? = nil)
        strings.reject!(&.empty?)

        @client.puts strings.join("\n")
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

      def join
        @client = Crirc::Network::Client.new(
          ip: "irc.chat.twitch.tv",
          pass: ENV["TWITCH_CHAT_TOKEN"],
          port: 6697.to_u16,
          ssl: true,
          nick: "Evita",
          read_timeout: 300_u16,
        )
        client = @client
        if client
          client.connect
          client.join Crirc::Protocol::Chan.new("wyhaines")
        end
      end

      def part; end

      def set_topic(topic : String)
      end

      def shut_down
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

        puts strings.join("\n")
      end

      def shut_down
        puts
      end

      def read_input
        b = @bot
        return if b.nil?
        Readline.readline("#{b.name} > ")
      end

      def receive_input
        loop do
          begin
            input = read_input
            if input.nil?
              puts
              break
            end
            if EXIT_WORDS.includes?(input)
              puts("Got an exit word(#{input}); exiting")
              exit
            end
            b = @bot

            if !b.nil?
              msg = b.message(
                body: input,
                origin: origin,
                parameters: {"from" => @user.name}
              )

              b.health_check

              b.send(
                msg
              )
            else
              puts "Bot isn't connected."
            end
            # Fiber.yield
          rescue e : Exception
            puts e
          end
        end
      end
    end
  end
end
