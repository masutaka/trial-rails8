require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @alice = users(:alice)
    @post = posts(:one)
  end

  def log_in_as(user)
    post session_url, params: { email_address: user.email_address, password: "password" }
  end

  test "index should show only published posts for unauthenticated users" do
    get posts_url
    assert_response :success
    # 公開記事のみが表示される（alice_old_post, one, two）
    assert_select "#posts > a", count: 3
  end

  test "index should show published posts and own unpublished posts for authenticated users" do
    log_in_as(@alice)
    get posts_url
    assert_response :success
    # 公開記事 + Alice の未公開記事（alice_old_post, one, two, scheduled, draft）
    assert_select "#posts > a", count: 5
  end

  test "index should not show other users unpublished posts" do
    bob = users(:bob)
    log_in_as(bob)
    get posts_url
    assert_response :success
    # 公開記事 + Bob の未公開記事（alice_old_post, one, two, ready_to_publish）
    # Alice の scheduled と draft は表示されない
    assert_select "#posts > a", count: 4
  end

  test "should get new" do
    log_in_as(@alice)
    get new_post_url
    assert_response :success
  end

  test "should create post" do
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      log_in_as(@alice)
      assert_difference("Post.count") do
        post posts_url, params: { post: { body: @post.body, published_at: @post.published_at, slug: @post.slug, title: @post.title } }
      end

      assert_redirected_to post_url(Post.last)
    end
  end

  test "should show published post for unauthenticated users" do
    get post_url(@post)
    assert_response :success
  end

  test "author can view own unpublished post" do
    scheduled_post = posts(:scheduled)
    log_in_as(@alice)
    get post_url(scheduled_post)
    assert_response :success
  end

  test "other users cannot view unpublished post" do
    scheduled_post = posts(:scheduled)
    bob = users(:bob)
    log_in_as(bob)
    get post_url(scheduled_post)
    assert_response :not_found
  end

  test "unauthenticated users cannot view unpublished post" do
    scheduled_post = posts(:scheduled)
    get post_url(scheduled_post)
    assert_response :not_found
  end

  test "should get edit" do
    log_in_as(@alice)
    get edit_post_url(@post)
    assert_response :success
  end

  test "should update post" do
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      log_in_as(@alice)
      patch post_url(@post), params: { post: { body: @post.body, published_at: @post.published_at, slug: @post.slug, title: @post.title } }
      assert_redirected_to post_url(@post)
    end
  end

  test "should destroy post" do
    log_in_as(@alice)
    assert_difference("Post.count", -1) do
      delete post_url(@post)
    end

    assert_redirected_to posts_url
  end
end
