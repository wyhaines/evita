require "./user"
require "./room"

module Evita
  struct Source
    getter user : User
    getter room : Room?

    def initialize(@user : User, @room = nil); end

    def initialize(user : String, @room = nil)
      @user = User.new(user)
    end
  end
end
