require "source"

module Evita
  struct Message
    getter body : String
    getter source : Source
  end
end
