# == Schema Information
#
# Table name: notifications
#
#  id         :bigint           not null, primary key
#  read       :boolean          default(FALSE), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  post_id    :bigint           not null
#  user_id    :bigint           not null
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
#  fk_rails_...  (post_id => posts.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
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
    broadcast_updates
  end

  def broadcast_badge_update
    broadcast_updates
  end

  def broadcast_updates
    Turbo::StreamsChannel.broadcast_update_to(
      "notifications_#{user_id}",
      target: "notification_badge",
      partial: "notifications/badge",
      locals: { user: user }
    )

    Turbo::StreamsChannel.broadcast_update_to(
      "notifications_#{user_id}",
      target: "notification_dropdown",
      partial: "notifications/dropdown",
      locals: { user: user }
    )
  end
end
