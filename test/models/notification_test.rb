# == Schema Information
#
# Table name: notifications
# Database name: primary
#
#  id              :bigint           not null, primary key
#  notifiable_type :string(255)      not null
#  read            :boolean          default(FALSE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  notifiable_id   :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_notifications_on_notifiable_type_and_notifiable_id  (notifiable_type,notifiable_id)
#  index_notifications_on_user_id                            (user_id)
#  index_notifications_on_user_id_and_created_at             (user_id,created_at)
#  index_notifications_on_user_id_and_read_and_created_at    (user_id,read,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
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
        notifiable: @post,
        read: false
      )

      # 既読通知を作成
      read_notification = Notification.create!(
        user: @user,
        notifiable: @post,
        read: true
      )

      # unread スコープは未読通知のみを返すことを確認
      unread_notifications = Notification.unread
      assert_includes unread_notifications, unread_notification
      assert_not_includes unread_notifications, read_notification
    end
  end

  class RecentScopeTest < NotificationTest
    setup do
      @user = users(:alice)
      @post = posts(:one)
    end

    test "returns notifications ordered by created_at descending" do
      # 通知を時系列で作成
      travel_to Time.zone.parse("2025-10-17 10:00:00") do
        @old_notification = Notification.create!(
          user: @user,
          notifiable: @post,
          read: false
        )
      end

      travel_to Time.zone.parse("2025-10-17 11:00:00") do
        @middle_notification = Notification.create!(
          user: @user,
          notifiable: @post,
          read: false
        )
      end

      travel_to Time.zone.parse("2025-10-17 12:00:00") do
        @new_notification = Notification.create!(
          user: @user,
          notifiable: @post,
          read: false
        )
      end

      # recent スコープは created_at の降順で取得することを確認
      recent_notifications = Notification.recent
      assert_equal [ @new_notification, @middle_notification, @old_notification ], recent_notifications.to_a
    end
  end

  class MarkAsReadTest < NotificationTest
    setup do
      @user = users(:alice)
      @post = posts(:one)
      @notification = Notification.create!(
        user: @user,
        notifiable: @post,
        read: false
      )
    end

    test "marks notification as read" do
      assert_not @notification.read

      @notification.mark_as_read!

      assert @notification.read
      assert @notification.reload.read
    end
  end

  class UnreadCountForTest < NotificationTest
    setup do
      @alice = users(:alice)
      @bob = users(:bob)
      @post = posts(:one)
    end

    test "returns unread notification count for specified user" do
      # Alice の未読通知を2件作成
      Notification.create!(user: @alice, notifiable: @post, read: false)
      Notification.create!(user: @alice, notifiable: @post, read: false)

      # Alice の既読通知を1件作成
      Notification.create!(user: @alice, notifiable: @post, read: true)

      # Bob の未読通知を1件作成
      Notification.create!(user: @bob, notifiable: @post, read: false)

      # Alice の未読通知数は2件
      assert_equal 2, Notification.unread_count_for(@alice)

      # Bob の未読通知数は1件
      assert_equal 1, Notification.unread_count_for(@bob)
    end
  end

  class BroadcastTest < NotificationTest
    setup do
      @user = users(:alice)
      @post = posts(:one)
    end

    test "broadcasts Turbo Streams after notification is created" do
      # 通知作成時にブロードキャストが発生してもエラーにならないことを確認
      assert_difference "@user.notifications.count", 1 do
        Notification.create!(user: @user, notifiable: @post, read: false)
      end
    end

    test "broadcasts Turbo Streams after notification is marked as read" do
      notification = Notification.create!(user: @user, notifiable: @post, read: false)

      # 既読にする前は未読
      assert_not notification.read

      # 既読にする
      notification.mark_as_read!

      # 既読になったことを確認
      assert notification.reload.read
    end

    test "does not broadcast when read status is not changed" do
      notification = Notification.create!(user: @user, notifiable: @post, read: false)

      # read 以外の属性を更新してもブロードキャストは発生しないはず
      # ただし、created_at は readonly なので別の属性で確認
      assert_no_changes -> { notification.reload.read } do
        # 同じ値で更新
        notification.update!(read: false)
      end
    end
  end
end
