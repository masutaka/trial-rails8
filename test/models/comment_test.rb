# == Schema Information
#
# Table name: comments
#
#  id         :integer          not null, primary key
#  body       :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  post_id    :integer          not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_comments_on_post_id  (post_id)
#  index_comments_on_user_id  (user_id)
#
# Foreign Keys
#
#  post_id  (post_id => posts.id) ON DELETE => cascade
#  user_id  (user_id => users.id) ON DELETE => cascade
#
require "test_helper"

class CommentTest < ActiveSupport::TestCase
  def setup
    @comment = comments(:one)
  end

  # バリデーションのテスト
  test "should be valid with valid attributes" do
    assert @comment.valid?
  end

  test "should require body" do
    @comment.body = nil
    assert_not @comment.valid?
    assert_includes @comment.errors[:body], "can't be blank"
  end

  test "should require body to be at least 1 character" do
    @comment.body = ""
    assert_not @comment.valid?
    assert_includes @comment.errors[:body], "is too short (minimum is 1 character)"
  end

  test "should not accept body longer than 10000 characters" do
    @comment.body = "a" * 10001
    assert_not @comment.valid?
    assert_includes @comment.errors[:body], "is too long (maximum is 10000 characters)"
  end

  test "should accept body with exactly 10000 characters" do
    @comment.body = "a" * 10000
    assert @comment.valid?
  end

  # アソシエーションのテスト
  test "should belong to post" do
    assert_respond_to @comment, :post
    assert_instance_of Post, @comment.post
  end

  test "should belong to user" do
    assert_respond_to @comment, :user
    assert_instance_of User, @comment.user
  end

  test "should require post" do
    @comment.post = nil
    assert_not @comment.valid?
    assert_includes @comment.errors[:post], "must exist"
  end

  test "should require user" do
    @comment.user = nil
    assert_not @comment.valid?
    assert_includes @comment.errors[:user], "must exist"
  end
end
