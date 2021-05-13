require "twitch_event_sub"

class Evita::TwitchEventSubDriver < TwitchEventSub::HttpServer::TwitchHandler
  def handle_channel_follow(params)
    puts "GOT A CHANNEL:FOLLOW"
    puts params.inspect
  end

  def handle_user_update(params)
    puts "GOT A USER:UPDATE"
    puts params.inspect
  end
end
