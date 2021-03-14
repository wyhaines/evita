require "readline"

module Evita
  module Adapters
    class Shell < Adapter
      EXIT_WORDS = %w(exit quit)

      def initialize(@bot)
        super
        @user = User.new(adapter: self, name: "Shell User")
      end

      def origin
        @pipeline.is_a?(Pipeline) ? @pipeline.origin : nil
      end

      def service
        "shell"
      end

      def namespace
        "shell"
      end

      def roster(room)
        [user]
      end

      def run
        join
        @output_proc = spawn(name: "receive_output for #{self.class}:#{@user.name}") { receive_output }
        @input_proc = spawn(name: "receive_input for #{self.class}:#{@user.name}") { receive_input }
      end

      def join; end

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
      ensure
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
          input = read_input
          if input.nil?
            puts
            break
          end
          exit if EXIT_WORDS.includes?(input)

          b = @bot
          if !b.nil?
            b.send(
              b.message(
                body: input,
                origin: origin,
                parameters: {"from" => @user.name}
              )
            )
          end
          Fiber.yield
        end
      end
    end
  end
end
