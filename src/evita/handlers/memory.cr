# en:
#   lita:
#     handlers:
#       memory:
#         help:
#           what:
#             syntax: what is <term>?
#             desc: returns the definition of <term>
#           remember:
#             syntax: remember [that] <term> is <definition>
#             desc: store the definition of <term> as <definition>
#           search:
#             syntax: search (terms|definitions) for <query>
#             desc: searches memory for your query
#           forget:
#             syntax: forget <term>
#             desc: forgets everything about <term>
#           all:
#             syntax: what do you remember?
#             desc: returns all the terms that have been memorized
#         response:

module Evita
  module Handlers
    # rubocop: disable Metrics/ClassLength
    # The memory handler stores information in redis for later recall.
    class Memory < Handler
      # remember [that] TERM is DEFINITION -> store
      # store TERM as DEFINITION -> store
      # add DEFINTION to TERM -> store
      # what do you (know|remember)? -> summary
      # (search|tell (me|us) about|find) (term|definition) TERM
      # what is TERM -> recall
      # what TERM is -> recall

      SEPARATOR          = /\s*(\b(?:as|is\s+also|is\s+not|isn't|is)\b|:|=|\+=|\-=)\s*/i.freeze
      ADDITIVE_OPS       = /is\s+also|\+=/.freeze
      SUBTRACTIVE_OPS    = /is\s+not|isn't|\-=/.freeze
      REMEMBER           = /\s*(?:\b(?:remember(?:\s+that)?|store)\b)\s*/i.freeze
      KNOW               = /\s*(?:\b(?:know|remember)\b)\s*/i.freeze
      WDYN               = /\s*(?:\bwhat\s+do\s+you#{KNOW})\s*/i.freeze
      SEARCH             = /\s*(?:\b(?:search(?:\s+for)?|find|tell\s+(?:\w+)\s+about)\b)\s*(?:the\s*)?/i.freeze
      TERM_OR_DEFINITION = /\s*(?:\b(terms?|definition)\b)\s*/i.freeze
      ARTICLE            = /\s*(?:\b(?:the|a|an)\b)\s*/i.freeze
      QUERY              = /\s*(?:\b(?:what(?:\s+is|\'s|\s+are)?(?:#{ARTICLE})?)\b)\s*/i.freeze
      CAPTURE            = /\s*(.*?)\s*/m.freeze
      REGEXP_CAPTURE     = %r{/(.*?)/[^/]*$}.freeze
      FORGET             = /\s*(?:\b(?:forget(?:\s+about)?|remove)\b)\s*(?:item\s+#{CAPTURE}\s+from)?\s*/i.freeze

      LOOKUP   = /#{QUERY}#{CAPTURE}(?:\bis\b)?\W*$/i.freeze
      SAVE     = /#{REMEMBER}#{CAPTURE}#{SEPARATOR}#{CAPTURE}[\.\?\!]*\z/m.freeze
      SUMMARY  = /#{WDYN}/.freeze
      DISCOVER = /#{SEARCH}#{TERM_OR_DEFINITION}(?:#{REGEXP_CAPTURE}|#{CAPTURE})\W*$/.freeze
      DELETE   = /#{FORGET}#{CAPTURE}\W*$/.freeze

      def handle(msg)
      end

      def evaluate(payload)
        if can_handle(payload[:message].body)
          [900_000, :via_memory]
        else
          [-999_998, "I don't know anything about what you just said."]
        end
      end

      def self.can_handle(message)
        details = parse_details(message)
        if details.first == :lookup && !known?(details.last)
          nil # Don't even bother handling if it can't be looked up.
        else
          details.first
        end
      end

      def self.redis_namespace
        Redis::Namespace.new("handlers:memory", redis: @redis.redis)
      end

      def self.parse_details(message)
        case message
        when SUMMARY
          summary_details(Regexp.last_match)
        when LOOKUP
          lookup_details(Regexp.last_match)
        when SAVE
          save_details(Regexp.last_match)
        when DISCOVER
          discover_details(Regexp.last_match)
        when DELETE
          delete_details(Regexp.last_match)
        else
          [nil]
        end
      end

      def self.summary_details(_last_match)
        [:summary]
      end

      def self.lookup_details(last_match)
        [:lookup, last_match[1]]
      end

      def self.save_details(last_match)
        [:save, last_match[1], last_match[2], last_match[3]]
      end

      def self.discover_details(last_match)
        [:discover, last_match[1], last_match[2] ? Regexp.new(last_match[2]) : last_match[3]]
      end

      def self.delete_details(last_match)
        [:forget, last_match[1], last_match[2]]
      end

      def reply(response)
        robot.send_message(@target, response)
      end

      def interrogate(payload)
        @message = payload[:message]
        details = self.class.parse_details(@message.body)
        __send__(details.first, *details[1..-1])
      end

      def lookup(term)
        @message.reply(format_definition(term, definition(term)))
      end

      def save(term, operation, defn)
        case operation
        when ADDITIVE_OPS
          add_term(term, defn)
        when SUBTRACTIVE_OPS
          subtract_term(term, defn)
        else
          save_term(term, defn)
        end
      end

      def save_term(term, defn)
        write(term, defn, @message.user.id)
        @message.reply(format_confirmation(term, definition(term)))
      end

      def add_term(term, defn)
        ary = arrayify_definition_for(term)
        ary << defn
        write(term, ary.to_json, @message.user.id)
        @message.reply(format_confirmation(term, preformat_definition(definition(term))))
      end

      def subtract_term(term, _definition)
        ary = arrayify_definition_for(term)
        ary.delete(defn)
        write(term, ary.to_json, @message.user.id)
        @message.reply(format_deletion(term))
      end

      def arrayify_definition_for(term)
        d = definition(term)
        safe_json_parse(d[:term]) || [d[:term]]
      end

      def safe_json_parse(json)
        JSON.parse(json)
      rescue StandardError
        nil
      end

      def summary
        @message.reply(format_all_the_terms(fetch_all_terms.sort.join("\n - ")))
      end

      def discover(type, query)
        mt = matching_terms(type, query)
        if mt.empty?
          "No matching `#{type}` found."
        else
          @message.reply(format_search(mt.sort.join("\n - ")))
        end
      end

      def forget(one, two)
        nth = one
        term = two
        if nth && (ary = safe_json_parse(definition(term)[:term]))
          ary.delete_at(nth.to_i - 1) && write(term, ary.to_json, @message.user.id)
          response = "Item #{nth} has been removed from #{term}"
        else
          delete(term)
          response = format_deletion(term)
        end
        @message.reply(response)
      end

      def matching_terms(type, query)
        if type == "term"
          terms = fetch_all_terms
          extract_matching_terms(query, terms)
        else
          extract_terms_from_matching_definitions(query)
        end
      end

      def extract_matching_terms(query, terms)
        log.info("QUERY: #{query.inspect}")
        case query
        when Regexp
          terms.select { |term| term =~ query }
        else
          terms.select { |term| term.includes?(query) }
        end
      end

      def extract_terms_from_matching_definitions(query)
        case query
        when Regexp
          fetch_all.select { |_term, definition| definition =~ query ? true : nil }
        else
          fetch_all.select { |_term, definition| definition.includes?(query) }
        end.map { |term, _definition| term }
      end

      def self.known?(term)
        ns = redis_namespace
        ns.exists(term.downcase)
      end

      def known?(term)
        redis.exists(term.downcase)
      end

      def fetch_all
        results = Hash(String, String).new
        redis.scan_each(count: 1000) do |term|
          definition = redis.hmget(term, "definition")[0]
          results[term] = definition
        end
        results
      end

      def fetch_all_terms
        terms = [] of String
        redis.scan_each(count: 1000) { |term| terms << term }
        terms
      end

      def format_all_the_terms(terms)
        "These are all the terms that I remember:\n - #{terms}"
      end

      def format_search(terms)
        "The following terms matched your query:\n - #{terms}"
      end

      def format_deletion(term)
        "OK. I won't remember what `#{term}` is."
      end

      def format_confirmation(term, definition)
        "OK, I'll remember that `#{term}` is\n#{definition}"
      end

      def format_definition(term, defn)
        "`#{term}` is\n#{definition(term)}\n"
      end

      def preformat_definition(defn)
        ary = safe_json_parse(defn[:term])
        if ary
          preformatted_definition = String.new
          ary.each_with_index { |item, index| preformatted_definition << "#{index + 1}. #{item}\n" }
        else
          preformatted_definition = defn[:term]
        end
        preformatted_definition
      end

      def definition(term)
        result = redis.hmget(term.downcase, "definition", "hits", "userid")
        redis.hincrby(term.downcase, "hits", 1)
        record = {
          term:   result[0],
          hits:   result[1],
          userid: result[2],
        }
        record
      end

      def delete(term)
        redis.del(term.downcase)
      end

      def write(term, definition, userid)
        redis.hset(term.downcase, "definition", definition)
        redis.hset(term.downcase, "userid", userid)
        redis.hset(term.downcase, "hits", 0)
      end
    end
  end
end
