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
require "test_helper"

class NotificationTest < ActiveSupport::TestCase
  class UnreadScopeTest < NotificationTest
    setup do
      @user = users(:alice)
      @post = posts(:one)
    end

    test "returns only unread notifications" do
      # 未読通知を作成
      unread_notification = Notification.create!(
        user: @user,
        post: @post,
        read: false
      )

      # 既読通知を作成
      read_notification = Notification.create!(
        user: @user,
        post: @post,
        read: true
      )

      # unread スコープは未読通知のみを返すことを確認
      unread_notifications = Notification.unread
      assert_includes unread_notifications, unread_notification
      assert_not_includes unread_notifications, read_notification
    end
  end
end
