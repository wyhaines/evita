require "openai"

class Array
  def pick_one
    self[rand(self.size)]
  end
end

module Evita
  module Handlers
    class GPT3 < Handler
      PREAMBLE       = "The following is a conversation with an assistant named Evita. The assistant is helpful, creative, and witty.\n\n"
      SEGMENT_OF_DAY = ->do
        t = Time.local

        if t < t.at_midday
          "morning"
        elsif t < (t.at_midday + 6.hours)
          "afternoon"
        else
          "evening"
        end
      end

      GOOD_TOD     = ->{ "Good #{SEGMENT_OF_DAY.call}! " }
      GENERIC_HIYA = ->do
        [
          "How are you?",
          "What is on your mind?",
          "Are you having a good day?",
          "What is on your mind?",
        ].pick_one
      end
      CONVERSATION_STARTERS = [
        ->{ "#{GOOD_TOD.call}#{GENERIC_HIYA.call}" },
        ->{ "How may I help you?" },
        ->{ "I am here to help you." },
      ]

      @conversations : Hash(String, Array(String))
      @openai : OpenAI::Client

      def self.conversation_starter
        "#{Evita.bot.name}: My name is #{Evita.bot.name}. #{CONVERSATION_STARTERS.pick_one.call}"
      end

      def self.prune_reply(reply)
        remove_extra_conversation(
          trim_unfinished_sentence(
            reply.split("\n", 2).first
          ))
      end

      def self.trim_unfinished_sentence(reply)
        reply.sub(/[^\.!\?]*$/, "")
      end

      def self.remove_extra_conversation(reply)
        "#{Evita.bot.name}: #{reply.sub(/^[\w\s]*:\s*(.*?)$/m, "\\1")}"
      end

      def initialize(@bot)
        super

        @openai = OpenAI::Client.new(api_key: ENV.fetch("OPENAI_API_KEY"), default_engine: "davinci")
        @conversations = Hash(String, Array(String)).new do |h, k|
          h[k] = [GPT3.conversation_starter]
        end
      end

      def evaluate(msg)
        ppl = @pipeline

        msg.send_evaluation(
          relevance: 0,
          certainty: 1000000,
          receiver: ppl.origin
        ) if ppl
      end

      def handle(msg)
        from = msg.parameters["from"]? || "anonymous"
        conversation = @conversations[from]
        conversation << "#{from}: #{msg.body.join("\n")}"
        conversation.shift if conversation.size > 10
        completion = @openai.completions(
          prompt: PREAMBLE + conversation.join("\n"),
          max_tokens: 21 + rand(20),
          temperature: 0.9,
          stop: "#{from}:"
        )

        reply = ""
        limit = 3
        loop do
          reply = GPT3.prune_reply(
            completion.choices.first.text.strip
          )
          cleanliness = @openai.filter(conversation.join("\n") + reply)
          break if cleanliness.choices.first.text.to_i < 2
          limit -= 1
          if limit == 0
            reply = "#{@bot.name}: That's inappropriate for me to say. Maybe we should change the subject?"
            break
          end
        end

        if reply.strip.empty?
          puts completion.inspect
        end

        conversation << reply
        msg.reply(body: reply)
      end
    end
  end
end
