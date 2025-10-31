require "test_helper"

class FollowsControllerTest < ActionDispatch::IntegrationTest
  class CreateTest < FollowsControllerTest
    setup do
      @alice = users(:alice)
      @bob = users(:bob)
    end

    test "redirects unauthenticated users" do
      post user_follow_path(@bob.username)
      assert_redirected_to new_session_url
    end

    test "creates a follow when authenticated" do
      log_in_as(@alice)

      assert_difference "Follow.count", 1 do
        post user_follow_path(@bob.username), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end

      assert @alice.following?(@bob)
      assert_response :success
    end

    test "creates a notification when following a user" do
      log_in_as(@alice)

      assert_difference "Notification.count", 1 do
        post user_follow_path(@bob.username), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end

      notification = Notification.find_by(user: @bob, notifiable_type: "Follow")
      assert_not_nil notification
      assert_equal false, notification.read
    end

    test "cannot follow yourself" do
      log_in_as(@alice)

      assert_no_difference "Follow.count" do
        post user_follow_path(@alice.username), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end
    end

    test "idempotent when already following" do
      log_in_as(@alice)
      @alice.follow(@bob)

      assert_no_difference "Follow.count" do
        post user_follow_path(@bob.username), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end
    end
  end

  class DestroyTest < FollowsControllerTest
    setup do
      @alice = users(:alice)
      @bob = users(:bob)
    end

    test "redirects unauthenticated users" do
      delete user_follow_path(@bob.username)
      assert_redirected_to new_session_url
    end

    test "destroys a follow when authenticated" do
      log_in_as(@alice)
      @alice.follow(@bob)

      assert_difference "Follow.count", -1 do
        delete user_follow_path(@bob.username), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end

      assert_not @alice.following?(@bob)
      assert_response :success
    end

    test "idempotent when not following" do
      log_in_as(@alice)

      assert_no_difference "Follow.count" do
        delete user_follow_path(@bob.username), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      end
    end
  end
end
