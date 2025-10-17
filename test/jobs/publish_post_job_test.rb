require "test_helper"

class PublishPostJobTest < ActiveJob::TestCase
  test "publishes a post that is ready to publish" do
    travel_to TEST_BASE_TIME do
      post = posts(:ready_to_publish)
      scheduled_at = post.published_at.to_i

      assert_not post.published, "Post should not be published initially"
      assert post.published_at <= Time.current, "published_at should be in the past"

      PublishPostJob.perform_now(post.id, scheduled_at)

      post.reload
      assert post.published, "Post should be published after job execution"
    end
  end

  test "skips publishing if post is already published" do
    travel_to TEST_BASE_TIME do
      post = posts(:alice_old_post)
      scheduled_at = post.published_at.to_i

      assert post.published, "Post should be published initially"

      PublishPostJob.perform_now(post.id, scheduled_at)

      post.reload
      assert post.published, "Post should remain published"
    end
  end

  test "skips publishing if published_at is in the future" do
    travel_to TEST_BASE_TIME do
      post = posts(:scheduled)
      scheduled_at = post.published_at.to_i

      assert_not post.published, "Post should not be published initially"
      assert post.published_at > Time.current, "published_at should be in the future"

      PublishPostJob.perform_now(post.id, scheduled_at)

      post.reload
      assert_not post.published, "Post should not be published"
    end
  end

  test "skips publishing if scheduled_at and current published_at differ" do
    travel_to TEST_BASE_TIME do
      post = posts(:ready_to_publish)
      original_published_at = post.published_at
      scheduled_at = original_published_at.to_i

      # ユーザーが公開日時を変更したケースをシミュレート
      new_published_at = 1.day.from_now
      post.update_column(:published_at, new_published_at)

      assert_not post.published, "Post should not be published initially"
      assert_not_equal scheduled_at, post.published_at.to_i, "scheduled_at and current published_at should differ"

      PublishPostJob.perform_now(post.id, scheduled_at)

      post.reload
      assert_not post.published, "Post should not be published when scheduled_at differs from current published_at"
    end
  end
end
