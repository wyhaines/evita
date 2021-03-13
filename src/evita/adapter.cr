require "./pipeline"

module Evita
  class Adapter
    @pipeline : Pipeline(Message) = Pipeline(Message).new
    @output_proc : Fiber?
    @input_proc : Fiber?
    #@bot : Robot
    @user : User = User.new(name: "Generic User")
    def initialize(@bot : Robot)
      @output_proc = nil
      @input_proc = nil
      @pipeline = @bot.register_adapter(self)
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

    def service; end
    def join; end
    def part; end
    def roster(room); end
    def run; end
    def send_output(strings : Array(String), target : String? = nil); end
    def receive_input; end
    def receive_output; end
    def set_topic(topic : String); end
    def shut_down; end
  end
end

require "./adapters/*"
