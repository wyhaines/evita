module Evita
  struct User
    getter id : Int32
    getter name : String

    def initialize(@name, @id = 1); end

    def to_s
      "#{@name}:#{@id}"
    end
  end
end
