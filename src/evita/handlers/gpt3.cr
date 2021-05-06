require "openai"

class Array
  def pick_one
    self[rand(self.size)]
  end
end

module Evita
  module Handlers
    class GPT3 < Handler
      PREAMBLE       = "You are an AI assistant named EVITA_NAME for the \"#wyhaines\" Twitch channel. You are polite, and happy, and helpful. You are an expert in computer science, software engineering, the Ruby programming language, and the Crystal programming language. You will greet people with a friendly greeting the first time that they follow or subscribe to the channel, and will be truthful when answering questions about software engineering or programming.\n\n"
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
        "#{Evita.bot.name}: #{CONVERSATION_STARTERS.pick_one.call}"
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
        reply.sub(/^[\w\s]*:\s*(.*?)$/m, "\\1")
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

        if will_handle?(msg)
          msg.send_evaluation(
            relevance: 0,
            certainty: 1000000,
            receiver: ppl.origin
          ) if ppl
        else
          msg.send_evaluation(
            relevance: -1000000,
            certainty: -1000000,
            receiver: ppl.origin
          ) if ppl
        end
      end

      def will_handle?(msg)
        can_handle?(msg) && authorized_to_handle?(msg)
      end

      def authorized_to_handle?(msg)
        msg.parameters["from"]? == "wyhaines"
      end

      def can_handle?(msg)
        match_direct = msg.body.join("\n") =~ /^\s*@?(evita|evita_bot|#{Evita.bot.name})\b/i
        puts match_direct.inspect
        match_direct
      end

      def handle(msg)
        from = msg.parameters["from"]? || "anonymous"
        conversation = @conversations[from]
        conversation << "#{from}: #{msg.body.join("\n")}"
        conversation.shift if conversation.size > 5
        puts conversation.inspect
        reply = ""
        limit = 3
        completion = uninitialized OpenAI::Completion
        loop do
          begin
            completion = @openai.completions(
              prompt: PREAMBLE.gsub(/EVITA_NAME/, Evita.bot.name) + conversation.join("\n"),
              max_tokens: 54 + rand(20),
              temperature: 0.9,
              stop: "#{from}:"
            )
          rescue
            next
          end
          reply = GPT3.prune_reply(
            completion.choices.first.text.strip
          )
          next if reply.strip.empty?
          cleanliness = @openai.filter(conversation.join("\n") + reply)
          break if cleanliness.choices.first.text.to_i < 2
          limit -= 1
          if limit == 0
            reply = "That's inappropriate for me to say. Maybe we should change the subject?"
            break
          end
        end

        if reply.strip.empty?
          puts completion.inspect
        end

        if reply =~ /@#{from}\b/
          conversation << "#{Evita.bot.name}: #{reply}"
        else
          conversation << "#{Evita.bot.name}: @#{from}: #{reply}"
        end
        msg.reply(body: "@#{from}: #{reply}")
      end
    end
  end
end
