require "test_helper"

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  class MarkAsReadTest < NotificationsControllerTest
    setup do
      @alice = users(:alice)
      @bob = users(:bob)
      @post = posts(:one)
      @alice_notification = Notification.create!(user: @alice, notifiable: @post)
      @bob_notification = Notification.create!(user: @bob, notifiable: @post)
    end

    test "redirects unauthenticated users" do
      patch mark_as_read_notification_path(@alice_notification)
      assert_redirected_to new_session_url
    end

    test "marks own notification as read" do
      log_in_as(@alice)
      patch mark_as_read_notification_path(@alice_notification)
      @alice_notification.reload
      assert @alice_notification.read
    end

    test "denies marking other user's notification as read" do
      log_in_as(@alice)
      patch mark_as_read_notification_path(@bob_notification)
      @bob_notification.reload
      assert_not @bob_notification.read
    end
  end

  class MarkAllAsReadTest < NotificationsControllerTest
    setup do
      @alice = users(:alice)
      @bob = users(:bob)
      @post = posts(:one)
      @alice_notification1 = Notification.create!(user: @alice, notifiable: @post)
      @alice_notification2 = Notification.create!(user: @alice, notifiable: @post)
      @bob_notification = Notification.create!(user: @bob, notifiable: @post)
    end

    test "redirects unauthenticated users" do
      patch mark_all_as_read_notifications_path
      assert_redirected_to new_session_url
    end

    test "marks all own notifications as read" do
      log_in_as(@alice)
      patch mark_all_as_read_notifications_path

      @alice_notification1.reload
      @alice_notification2.reload
      @bob_notification.reload

      assert @alice_notification1.read
      assert @alice_notification2.read
      assert_not @bob_notification.read
    end
  end
end
