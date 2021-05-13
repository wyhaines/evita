require "readline"

module Evita
  module Adapters
    # This adapter uses channels for input and output. It is intended
    # primarily for programatic use and/or testing.
    class Channel < Adapter
      getter input : Bus::Pipeline(String)
      getter output : Bus::Pipeline(String)

      def initialize(
        @bot,
        @input = Bus::Pipeline(String).new,
        @output = Bus::Pipeline(String).new,
        username : String = "no user"
      )
        super(@bot)
        @user = User.new(adapter: self, name: username)
      end

      def service
        "channel"
      end

      def namespace
        "channel"
      end

      def origin
        @pipeline.is_a?(Bus::Pipeline) ? @pipeline.origin : nil
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

        @output.send strings.join("\n")
      end

      def shut_down
        puts
      end

      def read_input
        b = @bot
        return if b.nil?
        @input.receive
      end

      def receive_input
        loop do
          begin
            input = read_input
            if input.nil?
              puts
              break
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
