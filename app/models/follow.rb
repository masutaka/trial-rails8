# == Schema Information
#
# Table name: follows
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  followed_id :bigint           not null
#  follower_id :bigint           not null
#
# Indexes
#
#  index_follows_on_followed_id                  (followed_id)
#  index_follows_on_follower_id                  (follower_id)
#  index_follows_on_follower_id_and_followed_id  (follower_id,followed_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (followed_id => users.id) ON DELETE => cascade
#  fk_rails_...  (follower_id => users.id) ON DELETE => cascade
#
class Follow < ApplicationRecord
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  has_many :notifications, as: :notifiable, dependent: :destroy

  validates :follower_id, uniqueness: { scope: :followed_id }
  validate :not_self_follow

  after_create_commit :create_notification

  private

  def not_self_follow
    if follower_id == followed_id
      errors.add(:followed_id, "cannot follow yourself")
    end
  end

  def create_notification
    Notification.create!(user: followed, notifiable: self, read: false)
  end
end
