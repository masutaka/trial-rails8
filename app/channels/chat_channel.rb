class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat"
  end

  def speak(data)
    message = data["message"].to_s.strip
    return if message.blank?

    payload = {
      message: message,
      sent_at: Time.current.iso8601,
      user_name: resolve_user_name
    }

    ActionCable.server.broadcast("chat", payload)
  end

  private
    def resolve_user_name
      current_user&.email_address.presence || "Guest"
    end
end
