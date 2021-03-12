module Evita
  class Adapter

    abstract def service
    abstract def join
    abstract def part
    abstract def roster
    abstract def run
    abstract def send_output
    abstract def receive_input
    abstract def receive_output
    abstract def set_topic
    abstract def shut_down

    getter bot : Robot

    def initialize(@bot)
      @output_proc : Fiber? = nil
      @input_proc : Fiber? = nil
    end
    
    def running?
      if input_running? && output_running?
        true
      elsif !input_running? && !output_running?
        false
      else
        :undefined
      end
    end

    def input_running?
      @input_proc.running?
    end

    def output_running?
      @output_proc.running?
    end
  end
end