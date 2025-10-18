class NotificationsController < ApplicationController
  def mark_as_read
    notification = Current.user.notifications.find_by(id: params[:id])
    notification&.mark_as_read!
    head :ok
  end

  def mark_all_as_read
    Current.user.notifications.unread.each(&:mark_as_read!)
    head :ok
  end
end
