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
require "turbo/broadcastable/test_helper"

class CommentTest < ActiveSupport::TestCase
  class ValidationTest < CommentTest
    setup do
      @comment = comments(:one)
    end

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
  end

  class AssociationTest < CommentTest
    setup do
      @comment = comments(:one)
    end

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

  class BroadcastTest < CommentTest
    include Turbo::Broadcastable::TestHelper

    setup do
      @comment = comments(:one)
    end

    test "should broadcast append and comment count on create" do
      post = posts(:one)
      user = users(:alice)

      assert_turbo_stream_broadcasts(post, count: 2) do
        Comment.create!(post: post, user: user, body: "New comment")
      end
    end

    test "should broadcast replace on update" do
      assert_turbo_stream_broadcasts(@comment.post, count: 1) do
        @comment.update!(body: "Updated comment body")
      end
    end

    test "should hide owner actions in broadcast visible to other users" do
      post = posts(:one)
      author = users(:alice)
      comment_body = "新しいリアルタイムコメントです"
      session = Session.new(user: author)

      created_comment = nil
      broadcasts = nil
      Current.set(session: session) do
        broadcasts = capture_turbo_stream_broadcasts(post) do
          created_comment = Comment.create!(post: post, user: author, body: comment_body)
        end
      end

      append_broadcast = broadcasts.find { |broadcast| broadcast["action"] == "append" && broadcast["target"] == "comments" }
      assert append_broadcast, "append broadcast for comments target should be present"
      html = append_broadcast.inner_html
      assert_includes html, comment_body
      assert_not_includes html, "編集"
      assert_not_includes html, "削除"
    end

    test "should show owner actions via user scoped broadcast" do
      post = posts(:one)
      author = users(:alice)
      comment_body = "所有者専用アクション確認コメント"
      session = Session.new(user: author)

      created_comment = nil
      broadcasts = nil
      Current.set(session: session) do
        broadcasts = capture_turbo_stream_broadcasts([ post, author ]) do
          created_comment = Comment.create!(post: post, user: author, body: comment_body)
        end
      end

      dom_id = ActionView::RecordIdentifier.dom_id(created_comment)
      replace_broadcast = broadcasts.find { |broadcast| broadcast["action"] == "replace" && broadcast["target"] == dom_id }
      assert replace_broadcast, "owner scoped stream should replace the comment frame with owner actions"
      html = replace_broadcast.inner_html
      assert_includes html, comment_body
      assert_includes html, "編集"
      assert_includes html, "削除"
    end

    test "should broadcast remove and comment count on destroy" do
      assert_turbo_stream_broadcasts(@comment.post, count: 2) do
        @comment.destroy
      end
    end
  end
end
