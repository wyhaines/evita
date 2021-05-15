require "bus"
require "./evita/*"
require "./evita/handlers/*"
require "benchmark"

bot = Evita::Robot.new

puts "Running with mode of #{bot.config.mode}"

if bot.config.mode == "run"
  endc = Channel(Nil).new

  # shell_adapter = Evita::Adapters::Shell.new(bot)
  irc_adapter = Evita::Adapters::Twitch.new(bot)
  echo_handler = Evita::Handlers::GPT3.new(bot)
  static_handler = Evita::Handlers::Static.new(bot)
  twitch_handler = Evita::Handlers::TwitchEventSub.new(bot)

  # shell_adapter.run
  irc_adapter.run
  echo_handler.run
  static_handler.run
  twitch_handler.run
  spawn(name: "exit handler") {
    begin
      sleep 100000; endc.send(nil)
    rescue e : Exception
      puts "This shouldn't happen: #{e}"
    end
  }
  endc.receive
  # end
end
