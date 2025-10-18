require "test_helper"

class NotifyPublicationJobTest < ActiveJob::TestCase
  test "全ユーザー（作成者除く）に通知を作成する" do
    post = posts(:ready_to_publish)
    author = post.user
    other_user = users(:alice) # ready_to_publish の作成者は bob なので alice は別ユーザー

    assert_difference "Notification.count", 1 do
      NotifyPublicationJob.perform_now(post.id)
    end

    # 作成者以外のユーザーに通知が作成されること
    notification = Notification.find_by(post: post, user: other_user)
    assert_not_nil notification
    assert_equal post.id, notification.post_id
    assert_equal other_user.id, notification.user_id
    assert_equal false, notification.read

    # 作成者には通知が作成されないこと
    author_notification = Notification.find_by(post: post, user: author)
    assert_nil author_notification
  end

  test "記事が見つからない場合は何もしない" do
    invalid_post_id = 999999

    assert_no_difference "Notification.count" do
      assert_nothing_raised do
        NotifyPublicationJob.perform_now(invalid_post_id)
      end
    end
  end
end
