require "./evita/*"
require "benchmark"

endc = Channel(Nil).new

e = Evita::Robot.new

shell_adapter = Evita::Adapters::Shell.new(e)
echo_handler = Evita::Handlers::Echo.new(e)

shell_adapter.run
echo_handler.run

# spawn { endc.send(nil) }
endc.receive
