module Evita
  class Adapter

    abstract def service
    abstract def join
    abstract def part
    abstract def roster
    abstract def run
    abstract def send_output
    abstract def set_topic
    abstract def shut_down

    getter bot : Robot

    def initialize(@bot)
    end
    
  end
end