struct Timeout
  class Error < Exception
  end
end

def sleep(seconds : Number)
  Crystal::Scheduler.sleep(0.seconds)
  Crystal::Scheduler.sleep(seconds.seconds)
end

def sleep(time : Time::Span)
  Crystal::Scheduler.sleep(0.seconds)
  Crystal::Scheduler.sleep(time)
end

# This timeout implementation wraps a block inside of another fiber.
# Because there isn't a pre-emptive schedule, timeouts can not be externally
# forced if the code inside of the block doesn't allow opportunities for
# the scheduler to move execution to another fiber. If that is permitted,
# through IO, or sleep, or yields, then this method can work to enforce a
# timeout around code that might otherwise block.
def timeout(
  seconds : Number,
  raise_on_exception : Bool = true,
  &blk
)
  fiber_state = :unstarted
  fiber_error = nil
  current_fiber = Fiber.current
  timeout_fiber = Fiber.new(name: "Timeout --#{blk}--#{seconds}") {
    fiber_state = :started
    begin
      blk.call
    rescue e : Exception
      fiber_state = :error
      fiber_error = e
    end
    fiber_state = :finished
    current_fiber.resume
  }
  Fiber.timeout(seconds.seconds)
  timeout_fiber.resume
  Fiber.cancel_timeout
  raise fiber_error.not_nil! if fiber_state == :error
  raise Timeout::Error.new if fiber_state != :finished && raise_on_exception

  fiber_state
end
