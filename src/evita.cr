require "./evita/*"
require "benchmark"

endc = Channel(Nil).new

e = Evita::Robot.new

shell_adapter = Evita::Adapters::Shell.new(e)
echo_handler = Evita::


#spawn { endc.send(nil) }
endc.receive
