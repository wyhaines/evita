require "./evita/*"
require "benchmark"

bot = Evita::Robot.new

if bot.config.mode == "run"
  endc = Channel(Nil).new

  shell_adapter = Evita::Adapters::Shell.new(bot)
  echo_handler = Evita::Handlers::GPT3.new(bot)
  static_handler = Evita::Handlers::Static.new(bot)

  shell_adapter.run
  echo_handler.run
  static_handler.run
  spawn(name: "exit handler") {
    begin
      endc.send(nil)
    rescue e : Exception
      puts "This shouldn't happen: #{e}"
    end
  }
  endc.receive
end
