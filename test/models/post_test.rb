require "test_helper"

class PostTest < ActiveSupport::TestCase
  def setup
    @post = posts(:one)
  end

  # アソシエーションのテスト
  test "should have many comments" do
    assert_respond_to @post, :comments
  end

  test "should return comments associated with post" do
    assert_includes @post.comments, comments(:one)
    assert_includes @post.comments, comments(:two)
  end

  # dependent: :destroy のテスト
  test "should destroy associated comments when post is destroyed" do
    post = posts(:one)
    comment_ids = post.comments.pluck(:id)

    assert_not_empty comment_ids, "Post should have comments before destruction"

    post.destroy

    comment_ids.each do |comment_id|
      assert_nil Comment.find_by(id: comment_id), "Comment #{comment_id} should be destroyed"
    end
  end

  # published スコープのテスト
  test "published scope should return only published posts" do
    published_posts = Post.published

    assert_includes published_posts, posts(:one)
    assert_includes published_posts, posts(:two)
    assert_not_includes published_posts, posts(:scheduled)
    assert_not_includes published_posts, posts(:draft)
    assert_not_includes published_posts, posts(:ready_to_publish)
  end

  # scheduled スコープのテスト
  test "scheduled scope should return unpublished posts with future published_at" do
    scheduled_posts = Post.scheduled

    assert_includes scheduled_posts, posts(:scheduled)
    assert_not_includes scheduled_posts, posts(:one)
    assert_not_includes scheduled_posts, posts(:two)
    assert_not_includes scheduled_posts, posts(:draft)
    assert_not_includes scheduled_posts, posts(:ready_to_publish)
  end

  # draft スコープのテスト
  test "draft scope should return unpublished posts without published_at" do
    draft_posts = Post.draft

    assert_includes draft_posts, posts(:draft)
    assert_not_includes draft_posts, posts(:one)
    assert_not_includes draft_posts, posts(:two)
    assert_not_includes draft_posts, posts(:scheduled)
    assert_not_includes draft_posts, posts(:ready_to_publish)
  end

  # ready_to_publish スコープのテスト
  test "ready_to_publish scope should return unpublished posts with past or present published_at" do
    ready_posts = Post.ready_to_publish

    assert_includes ready_posts, posts(:ready_to_publish)
    assert_not_includes ready_posts, posts(:one)
    assert_not_includes ready_posts, posts(:two)
    assert_not_includes ready_posts, posts(:scheduled)
    assert_not_includes ready_posts, posts(:draft)
  end

  # scheduled? メソッドのテスト
  test "scheduled? should return true for scheduled posts" do
    assert posts(:scheduled).scheduled?
    assert_not posts(:one).scheduled?
    assert_not posts(:draft).scheduled?
    assert_not posts(:ready_to_publish).scheduled?
  end
end
