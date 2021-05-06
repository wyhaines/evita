require "./irc"

module Evita
  module Adapters
    class Twitch < Irc

      def join
        super
      end

    end
  end
end
