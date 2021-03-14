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

      def initialize(@bot)
        super

        @openai = OpenAI::Client.new(api_key: ENV.fetch("OPENAI_API_KEY"), default_engine: "davinci")
        @conversations = Hash(String, Array(String)).new do |h, k|
          h[k] = [conversation_starter]
        end
      end

      def conversation_starter
        "#{@bot.name}: My name is #{@bot.name}. #{CONVERSATION_STARTERS.pick_one.call}"
      end

      def prune_reply(reply)
        remove_extra_conversation(
          cut_unfinished_sentence(
            reply.split("\n", 2).first
          ))
      end

      def cut_unfinished_sentence(reply)
        reply.sub(/[^\.!\?]*$/, "")
      end

      def remove_extra_conversation(reply)
        "#{@bot.name}: #{reply.sub(/^[\w\s]*:\s*(.*?)$/m, "\\1")}"
      end

      def listen
        spawn {
          counter = 0
          ppl = @pipeline
          loop do
            begin
              msg = ppl.receive if !ppl.nil?

              if !msg.nil?
                counter += 1
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
                  reply = prune_reply(
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
                puts "sending -> #{reply}"
                msg.reply(body: reply)
              end
            rescue e : Exception
              puts "boom"
              puts e
            end
          end
        }
      end
    end
  end
end
