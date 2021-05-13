require "./spec_helper"

describe Evita do
  it "can round-trip from adapter <-> handler" do
    ARGV.replace(["test", "-n", "test bot"])
    bot = Evita::Robot.new
    channel_adapter = Evita::Adapters::Channel.new(bot)
    echo_handler = Evita::Handlers::Echo.new(bot)

    input_stepper = Bus::Pipeline(String?).new
    # output_stepper = Bus::Pipeline(String?).new

    channel_adapter.run
    echo_handler.run

    spawn(name: "Input stepper motor") do
      loop do
        str = input_stepper.receive
        break if str.nil?

        channel_adapter.input.send str
      end
    end

    # spawn(name: "Output stepper motor") do
    #   while output_stepper.receive do
    #     str = channel_adapter.output.receive

    #   end
    # end

    input_stepper.send "test"
    channel_adapter.output.receive.should eq "1: test"

    input_stepper.send "test again"
    channel_adapter.output.receive.should eq "2: test again"
  end
end
