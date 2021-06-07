require "digest/sha256"

module Evita
  module Handlers
    # This handler will volunteer to handle a message if it
    # has a specific response to the message payload that makes
    # sense. i.e. if a message goes out to be handled, with
    # content of "!futurestack", and this handler has been
    # given static content for that message, then it will bid
    # very high in order to answer the message because it has
    # absolute certainty that it has an appropriate response to
    # the message.
    # If it does not have a match, though, it will decline to
    # handle the message at all.
    class Static < Evita::Handler
      class Config
        include YAML::Serializable
        include YAML::Serializable::Unmapped

        @[YAML::Field(key: "asset_index")]
        getter asset_index : String = "/dev/null"

        include Send
      end

      # This records the vital state information of the asset index file.

      class FileState
        property path : Path
        property last_modified : Time?
        property hash : String?

        def initialize(
          @path : Path = Path.new("/dev/null"),
          @last_modified : Time? = nil,
          @hash : String? = nil
        )
        end

        def hash_for_path
          Digest::SHA256.new.file(path).final.hexstring
        end

        def modified?
          self.hash != hash_for(path)
        end

        def new_state
          if path && File.exists?(path)
            info = File.info(path)
            hash = hash_for_path
            FileState.new(
              path: path,
              last_modified: info.modification_time,
              hash: hash
            )
          else
            FileState.new
          end
        rescue e : Exception
          return FileState.new
        end
      end

      AssetState = FileState.new
      AssetIndex = Hash(String, String).new

      # I don't think that I actually want to take this approach of compiling things in directly.
      #
      # macro from_proc(path)
      #   {% code = read_file?(path) %}
      #   ->() { {{ code.id }} }
      # end

      # macro from_content(path)
      #   {% content = read_file?(path) %}
      #   {{ content.stringify }}
      # end

      # macro dbg(path)
      #   puts path
      # end

      # Data = {
      #   "marco"       => "polo",
      #   "ping"        => "pong",
      #   "futurestack" => "Level up your observability game at FutureStack, a free virtual event May 25-27! https://bit.ly/futurestack-twitch",
      # }

      def asset_index_path
        if AssetState.path
          AssetState.path
        else
          puts "ROBOT CONFIG"
          pp Robot.config
          #AssetState.path = Path.new(Robot.config.static.try(&.asset_index) || "/dev/null")
          AssetState.path = Path.new("/dev/null")
        end
      end

      def evaluate(msg)
        ppl = @pipeline
        if will_handle?(msg)
          msg.send_evaluation(
            relevance: 2,
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
        command(msg)
      end

      def asset_exists?(cmd)
        if asset_index_path && cmd
          File.exists?(File.expand_path(File.join(asset_index_path.as(String), cmd)))
        else
          false
        end
      end

      def command(msg)
        match = /^\s*!\s*(\w+)/.match(msg.body.join)
        puts "#{msg.body.join} -- #{match.inspect}"
        match && match[1]
      end

      def handle(msg)
        cmd = command(msg)

        reply = ""

        if resource_exists(cmd)
          reply = handle_resource(cmd)
        else
          reply = "I'm sorry. I don't know the command \"#{cmd}\"."
        end

        msg.reply(body: reply) if reply
      end

      def resource_exists(cmd)
        refresh_asset_index && AssetIndex.has_key?(cmd)
      end

      Static_R = /^static\s*:\s*(.*)/i
      Exec_R   = /^exec\s*:\s*(.*)/i

      def handle_resource(cmd)
        resource = AssetIndex[cmd]
        # TODO: This would be a lot more powerful if Mustache were supported
        # within the asset, and if there were some standard set of model data
        # that can be tapped into, as well.
        case resource
        when Static_R
          # Return the contents of the file.
          path = $1
          File.read(path)
        when Exec_R
          # TODO: make this smarter so that if the execute bit isn't set,
          # it will try to figure out if it can run the file some other way,
          # e.g. ruby foo.rb
          path = $1
          `#{path}`
        else
          # Just return the text of the asset.
          resource
        end
      end

      def refresh_asset_index
        if asset_index_path &&
           File.info(asset_index_path).modification_time != AssetState.last_modified &&
           AssetState.hash != AssetState.hash_for_path
          read_asset_index
        end
      end

      def transform_yaml_hash(hash)
        h2 = Hash(String, String).new
        hash.as_h.each { |k, v| h2[k.as_s] = v.as_s }

        h2
      end

      def read_asset_index
        AssetIndex.clear
        AssetIndex.merge! transform_yaml_hash(YAML.parse(File.read(asset_index_path)))
      end
    end
  end

  class Config
    @[YAML::Field(key: "static", emit_null: true)]
    getter static : Handlers::Static::Config?
  end
end
