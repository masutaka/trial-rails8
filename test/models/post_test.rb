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
end
