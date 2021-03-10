require "user"
require "room"

module Evita
  struct Source
    getter user : User
    getter room : Room?

    def initialize(@user, @room = nil)
    end
    
  end
end