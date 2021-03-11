require "./evita/*"
require "benchmark"

module Evita
  class Robot
    getter bus : Bus

    def initialize
      @bus = Bus.new
    end
  end
end

class Handler
  @pipeline : Evita::Pipeline(Evita::Message)?

  def initialize(@value = "", @pipeline : Evita::Pipeline(Evita::Message)? = nil)
  end

  def subscribe(bus, tags)
    @pipeline = bus.subscribe(tags)
  end

  def listen
    spawn {
      ppl = @pipeline
      loop do
        msg = ppl.receive if !ppl.nil?
        if !msg.nil?
          msg.reply(body: "returning #{@value}", parameters: {"value" => @value})
        end
      end
    }
  end
end

endc = Channel(Nil).new

e = Evita::Robot.new

h = [] of Handler
iter = 10

iter.times do |x|
  h << Handler.new(value: (x*x).to_s)
  h[x].subscribe(e.bus, [x.to_s, "all"])
  h[x].listen
end

me = e.bus.subscribe(["me"])
e.bus.send(
  e.bus.message(
    body: "What is your value? >>",
    tags: ["5"],
    origin: me.origin
  )
)

got = me.receive
puts "<< #{got.body}"
puts "<< #{got.parameters["value"]}"

Benchmark.ips do |bm|
  bm.report do
    e.bus.send(
      e.bus.message(
        body: "What is your value? >>",
        tags: ["all"],
        origin: me.origin
      )
    )

    s = 0
    iter.times do |x|
      n = me.receive
      s += n.parameters["value"].to_i
    end
  end
end
# puts "total: #{s}"

spawn { endc.send(nil) }
endc.receive
