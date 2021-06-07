require "./spec_helper"

describe Evita do
  it "can round-trip from adapter <-> handler using the echo handler" do
    ARGV.replace(["test", "-n", "test bot"])
    bot = Evita::Robot.new
    channel_adapter = Evita::Adapters::Channel.new(
      bot: bot,
      input: Bus::Pipeline(String).new(1000),
      output: Bus::Pipeline(String).new(1000)
    )
    echo_handler = Evita::Handlers::Echo.new(bot)

    input_stepper = Bus::Pipeline(String?).new(1000)

    channel_adapter.run
    echo_handler.run

    spawn(name: "Input stepper motor") do
      loop do
        str = input_stepper.receive
        break if str.nil?

        channel_adapter.input.send str
      end
    end

    input_stepper.send "test"
    channel_adapter.output.receive.should eq "1: test"

    input_stepper.send "test again"
    channel_adapter.output.receive.should eq "2: test again"

    # The next test is intended to just ensure that the message bus
    # keeps up, and that delivery happens as it should, in the order
    # that it should. If this blows up, it will timeout in 20 seconds.
    spawn(name: "hammer test") do
      100000.times { input_stepper.send "hammer" }
    end

    last_msg = ""

    timeout(
      seconds: 20,
      raise_on_exception: false
    ) do
      100000.times do
        last_msg = channel_adapter.output.receive
        sleep 0
      end
    end

    last_msg.should eq "100002: hammer"
  end

  it "can round-trip through the static handler" do
    ARGV.replace(["test", "-n", "test bot", "-k", ""])
    bot = Evita::Robot.new
    channel_adapter = Evita::Adapters::Channel.new(
      bot: bot,
      input: Bus::Pipeline(String).new(1000),
      output: Bus::Pipeline(String).new(1000)
    )
    echo_handler = Evita::Handlers::Static.new(bot)

    input_stepper = Bus::Pipeline(String?).new(1000)

    channel_adapter.run
    echo_handler.run

    spawn(name: "Input stepper motor") do
      loop do
        str = input_stepper.receive
        break if str.nil?

        channel_adapter.input.send str
      end
    end

    input_stepper.send "test"
    channel_adapter.output.receive.should eq "1: test"

    input_stepper.send "test again"
    channel_adapter.output.receive.should eq "2: test again"

    # The next test is intended to just ensure that the message bus
    # keeps up, and that delivery happens as it should, in the order
    # that it should. If this blows up, it will timeout in 20 seconds.
    spawn(name: "hammer test") do
      100000.times { input_stepper.send "hammer" }
    end

    last_msg = ""

    timeout(
      seconds: 20,
      raise_on_exception: false
    ) do
      100000.times do
        last_msg = channel_adapter.output.receive
        sleep 0
      end
    end

    last_msg.should eq "100002: hammer"
  end
end
