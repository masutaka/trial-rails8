require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @bob = users(:bob)
    @post = posts(:one)
    @comment = comments(:one)  # alice's comment on post :one
    @bob_comment = comments(:two)  # bob's comment on post :one
  end

  def log_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end

  # create アクションのテスト
  test "should create comment when logged in" do
    log_in_as(@alice)
    assert_difference("Comment.count") do
      post post_comments_url(@post), params: { comment: { body: "新しいコメントです。" } }
    end

    assert_redirected_to post_url(@post)
  end

  test "should not create comment when not logged in" do
    assert_no_difference("Comment.count") do
      post post_comments_url(@post), params: { comment: { body: "新しいコメントです。" } }
    end

    assert_redirected_to new_session_url
  end

  test "should not create comment with invalid params" do
    log_in_as(@alice)
    assert_no_difference("Comment.count") do
      post post_comments_url(@post), params: { comment: { body: "" } }
    end

    assert_response :unprocessable_entity
  end

  # edit アクションのテスト
  test "should get edit when owner" do
    log_in_as(@alice)
    get edit_comment_url(@comment)
    assert_response :success
  end

  test "should not get edit when not logged in" do
    get edit_comment_url(@comment)
    assert_redirected_to new_session_url
  end

  test "should not get edit when not owner" do
    log_in_as(@bob)
    get edit_comment_url(@comment)
    assert_redirected_to root_url
  end

  # update アクションのテスト
  test "should update comment when owner" do
    log_in_as(@alice)
    patch comment_url(@comment), params: { comment: { body: "更新されたコメント" } }
    assert_redirected_to post_url(@comment.post)

    @comment.reload
    assert_equal "更新されたコメント", @comment.body
  end

  test "should not update comment when not logged in" do
    original_body = @comment.body
    patch comment_url(@comment), params: { comment: { body: "更新されたコメント" } }
    assert_redirected_to new_session_url

    @comment.reload
    assert_equal original_body, @comment.body
  end

  test "should not update comment when not owner" do
    log_in_as(@bob)
    original_body = @comment.body
    patch comment_url(@comment), params: { comment: { body: "更新されたコメント" } }
    assert_redirected_to root_url

    @comment.reload
    assert_equal original_body, @comment.body
  end

  test "should not update comment with invalid params" do
    log_in_as(@alice)
    original_body = @comment.body
    patch comment_url(@comment), params: { comment: { body: "" } }
    assert_response :unprocessable_entity

    @comment.reload
    assert_equal original_body, @comment.body
  end

  # destroy アクションのテスト
  test "should destroy comment when owner" do
    log_in_as(@alice)
    assert_difference("Comment.count", -1) do
      delete comment_url(@comment)
    end

    assert_redirected_to post_url(@comment.post)
  end

  test "should not destroy comment when not logged in" do
    assert_no_difference("Comment.count") do
      delete comment_url(@comment)
    end

    assert_redirected_to new_session_url
  end

  test "should not destroy comment when not owner" do
    log_in_as(@bob)
    assert_no_difference("Comment.count") do
      delete comment_url(@comment)
    end

    assert_redirected_to root_url
  end
end
