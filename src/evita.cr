require "./evita/*"
require "benchmark"

endc = Channel(Nil).new

bot = Evita::Robot.new

shell_adapter = Evita::Adapters::Shell.new(bot)
echo_handler = Evita::Handlers::GPT3.new(bot)

shell_adapter.run
echo_handler.run

# spawn { endc.send(nil) }
endc.receive
