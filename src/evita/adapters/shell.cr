require "readline"

module Evita
  module Adapters
    class Shell < Adapter
      property user : String

      EXIT_WORDS = %w(exit quit)

      def initialize(@bot)
        super

        @user = User.new(name: "Shell User")
        @pipeline = @bot.subscribe(tags: ["user: #{user}"])
      end

      def roster(room)
        [user]
      end

      def run
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

      def run_loop
        loop do
          input = read_input
          if input.nil?
            puts
            break
          end
          break if exit_words.include?(input)
          @bot.send(
            @bot.message(
              body: "What is your value? >>",
              tags: ["5"],
              origin: me.origin
            )
          )
        end
      end

    end
  end
end