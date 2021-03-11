require "splay_tree_map"
require "uuid"

module Evita

  #####
  # A Bus sends messages to interested subscribers. Those subscribers
  # can reply to a message. Those replies will be routed back to the
  # original sender.
  class Bus
    # Generate a random UUID that does not already exist in the subscriptions.
    def self.origin_tag
      loop do
        id = UUID.random.to_s
        break if !@subscriptions.has_key?(id)
      end
    end

    def initialize
      @subscriptions = SplayTreeMap(String, Hash(Pipeline(Message), Bool)).new do |h, k|
        h[k] = Hash(Pipeline(Message), Bool).new
      end
      @subscribers = Hash(Pipeline(Message), Array(String)).new
      @pipeline = Pipeline(Message).new(20)
      handle_pipeline
    end

    # The pipeline into the bus exists primarily for message object to have
    # a queue that can be used to submit replies that are intended to go back
    # into the bus. This method creates a fiber that listens on the pipeline
    # and sends anything that it receives.
    private def handle_pipeline
      spawn(name: "Pipeline loop") {
        loop do
          msg = @pipeline.receive
          # This probably needs a way to protect against message loops.
          send(message: msg)
        end
      }
    end

    # Subscribe a new message consumer to the Bus
    def subscribe(tags = [] of String)
      pipeline = Pipeline(Message).new(10)
      tags << pipeline.origin
      tags.each do |tag|
        @subscriptions[tag][pipeline] = true
      end
      @subscribers[pipeline] = tags

      pipeline
    end

    # Remove a message consumer from the Bus
    def unsubscribe(pipeline)
      if tags = @subscribers[pipeline]?
        tags.each do |tag|
          hsh = @subscriptions[tag]?
          hsh.delete(pipeline)
        end
        @subscribers.delete(pipeline)
      end
    end

    # Generate a message for this bus.
    def message(
      body : String,
      origin : String? = nil,
      tags : Array(String) = [] of String,
      parameters : Hash(String, String) = Hash(String, String).new
    )
      Message.new(
        body: body,
        parameters: parameters,
        tags: tags,
        origin: origin,
        pipeline: @pipeline,
        bus: self
      )
    end

    # Send a message to the subscribers
    def send(message : Message)
      # It's quite possible for tag combinations to target the same
      # recipient via multiple tags. In those cases the system should
      # only send a given message one time, so the following code builds
      # a unique list of recipients.
      receivers = Hash(Pipeline(Message), Bool).new
      message.tags.each do |tag|
        if @subscriptions.has_key?(tag)
          @subscriptions[tag].each_key do |receiver|
            receivers[receiver] = true
          end
        end
      end

      receivers.keys.each do |receiver|
        spawn {
          receiver.send(message)
        }
      end
    end
  end
end
