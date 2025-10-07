class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat"
  end

  def speak(data)
    message = data["message"].to_s.strip
    return if message.blank?

    ActionCable.server.broadcast("chat", { message: message, sent_at: Time.current.iso8601 })
  end
end
