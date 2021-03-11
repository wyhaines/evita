require "./evita/*"

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
      msg = ppl.receive if !ppl.nil?
      if !msg.nil?
        puts "#{msg.body} -- #{@value}"
        msg.reply(body: "returning #{@value}", parameters: {"value" => @value})
      end
    }
  end
end

endc = Channel(Nil).new

e = Evita::Robot.new

h = [] of Handler
11.times do |x|
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

  e.bus.send(
  e.bus.message(
    body: "What is your value? >>",
    tags: ["all"],
    origin: me.origin
  )
)

s = 0
10.times do |x|
  n = me.receive
  puts "<<(#{x}) -- #{n.parameters["value"]}"
  s += n.parameters["value"].to_i
end

puts "total: #{s}"

spawn { endc.send(nil) }
endc.receive
