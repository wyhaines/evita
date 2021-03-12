module Evita
  struct User
    getter id : UInt64
    getter name : String

    def initialize(@name, @id = 1); end
  end
end
