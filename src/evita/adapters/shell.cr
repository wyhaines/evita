require "readline"

module Evita
  module Adapters
    class Shell < Adapter
      property user : String

      EXIT_WORDS = %w(exit quit)

      def initialize(@bot)
        super

        @user = User.new(name: "Shell User")
        @pipeline = @bot.register_adapter(self)
      end

      def origin
        @pipeline.is_a?(Pipeline) ? @pipeline.origin : nil
      end

      def roster(room)
        [user]
      end

      def run
        @output_proc = spawn(name: "receive_output for #{self.class.name}:#{@user.name}") {receive_output}
        @input_proc = spawn(name: "receive_input for #{self.class.name}:#{@user.name}") {receive_input}
      end

      def receive_output
        loop do
          msg = @pipeline.receive
          send_output(msg.body)
        end
      ensure
      end

      def send_output(strings : Array(String), _target : String? = nil)
        strings.reject!(&.empty?)

        puts strings
      end

      def shut_down
        puts
      end

      def read_input
        Readline.readline("#{bot.name} > ")
      end

      def receive_input
        loop do
          input = read_input
          if input.nil?
            puts
            break
          end
          break if exit_words.include?(input)
          @bot.send(
            @bot.message(
              body: input,
              origin: origin
            )
          )
        end
      end

    end
  end
end