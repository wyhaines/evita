module Evita
  struct Message
    getter body : String
    getter tags : Array(String)
    getter parameters : Hash(String, String)
    getter origin : String?
    getter pipeline : Pipeline(Message)

    def initialize(
      @pipeline,
      @bus : Bus,
      @body = "",
      @tags = [] of String,
      @parameters = Hash(String, String).new,
      @origin = nil
    )
    end

    private def reply_impl(message : Message)
      spawn {
        @pipeline.send(message)
      }
    end

    def reply(
      body = "",
      parameters : Hash(String, String) = Hash(String, String).new,
      tags = [] of String
    )
      local_origin = @origin
      tags << local_origin if !local_origin.nil?
      reply_impl(
        @bus.message(
          body: body,
          parameters: parameters,
          tags: tags,
          origin: origin
        )
      )
    end

    def reply(message : Message)
      reply_impl(message)
    end
  end
end
