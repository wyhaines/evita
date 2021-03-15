require "./evita/*"
require "benchmark"

bot = Evita::Robot.new

if bot.config.mode == "run"
  endc = Channel(Nil).new

  shell_adapter = Evita::Adapters::Shell.new(bot)
  echo_handler = Evita::Handlers::GPT3.new(bot)

  shell_adapter.run
  echo_handler.run
  spawn { endc.send(nil) }
  endc.receive
end
