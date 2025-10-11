require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @post = posts(:one)
  end

  def log_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end

  test "should get index" do
    get posts_url
    assert_response :success
  end

  test "should get new" do
    log_in_as(@alice)
    get new_post_url
    assert_response :success
  end

  test "should create post" do
    log_in_as(@alice)
    assert_difference("Post.count") do
      post posts_url, params: { post: { body: @post.body, published_at: @post.published_at, slug: @post.slug, title: @post.title } }
    end

    assert_redirected_to post_url(Post.last)
  end

  test "should show post" do
    get post_url(@post)
    assert_response :success
  end

  test "should get edit" do
    log_in_as(@alice)
    get edit_post_url(@post)
    assert_response :success
  end

  test "should update post" do
    log_in_as(@alice)
    patch post_url(@post), params: { post: { body: @post.body, published_at: @post.published_at, slug: @post.slug, title: @post.title } }
    assert_redirected_to post_url(@post)
  end

  test "should destroy post" do
    log_in_as(@alice)
    assert_difference("Post.count", -1) do
      delete post_url(@post)
    end

    assert_redirected_to posts_url
  end
end
