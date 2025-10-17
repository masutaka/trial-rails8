# == Schema Information
#
# Table name: notifications
#
#  id         :integer          not null, primary key
#  read       :boolean          default(FALSE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  post_id    :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_notifications_on_post_id                          (post_id)
#  index_notifications_on_user_id                          (user_id)
#  index_notifications_on_user_id_and_created_at           (user_id,created_at)
#  index_notifications_on_user_id_and_read_and_created_at  (user_id,read,created_at)
#
# Foreign Keys
#
#  post_id  (post_id => posts.id) ON DELETE => cascade
#  user_id  (user_id => users.id) ON DELETE => cascade
#
class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :post

  scope :unread, -> { where(read: false) }
  scope :recent, -> { order(created_at: :desc) }

  after_create_commit :broadcast_notification
  after_update_commit :broadcast_badge_update, if: :saved_change_to_read?

  def mark_as_read!
    update!(read: true)
  end

  def self.unread_count_for(user)
    where(user: user).unread.count
  end

  private

  def broadcast_notification
    broadcast_to_user
  end

  def broadcast_badge_update
    broadcast_to_user
  end

  def broadcast_to_user
    ActionCable.server.broadcast(
      "notifications_#{user_id}",
      { unread_count: Notification.unread_count_for(user) }
    )
  end
end
