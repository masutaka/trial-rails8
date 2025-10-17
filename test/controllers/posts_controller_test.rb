require "test_helper"

class PostsControllerTest < ActionDispatch::IntegrationTest
  class IndexTest < PostsControllerTest
    test "shows only published posts for unauthenticated users" do
      get posts_url
      assert_response :success
      # 公開記事のみが表示される（alice_old_post, one, two）
      assert_select "#posts > a", count: 3
    end

    test "shows published posts and own unpublished posts for authenticated users" do
      log_in_as(users(:alice))
      get posts_url
      assert_response :success
      # 公開記事 + Alice の未公開記事（alice_old_post, one, two, scheduled, draft）
      assert_select "#posts > a", count: 5
    end

    test "does not show other users unpublished posts" do
      log_in_as(users(:bob))
      get posts_url
      assert_response :success
      # 公開記事 + Bob の未公開記事（alice_old_post, one, two, ready_to_publish）
      # Alice の scheduled と draft は表示されない
      assert_select "#posts > a", count: 4
    end
  end

  class NewTest < PostsControllerTest
    setup do
      @alice = users(:alice)
    end

    test "succeeds" do
      log_in_as(@alice)
      get new_post_url
      assert_response :success
    end
  end

  class CreateTest < PostsControllerTest
    setup do
      @alice = users(:alice)
      @post = posts(:one)
    end

    test "creates post" do
      travel_to Time.zone.parse("2025-10-15 12:00:00") do
        log_in_as(@alice)
        assert_difference("Post.count") do
          post posts_url, params: { post: { body: @post.body, published_at: @post.published_at, slug: @post.slug, title: @post.title } }
        end

        assert_redirected_to post_url(Post.last)
      end
    end
  end

  class ShowTest < PostsControllerTest
    setup do
      @alice = users(:alice)
      @post = posts(:one)
      @scheduled_post = posts(:scheduled)
    end

    test "shows published post for unauthenticated users" do
      get post_url(@post)
      assert_response :success
    end

    test "allows author to view own unpublished post" do
      log_in_as(@alice)
      get post_url(@scheduled_post)
      assert_response :success
    end

    test "denies other users from viewing unpublished post" do
      log_in_as(users(:bob))
      get post_url(@scheduled_post)
      assert_response :not_found
    end

    test "denies unauthenticated users from viewing unpublished post" do
      get post_url(@scheduled_post)
      assert_response :not_found
    end
  end

  class EditTest < PostsControllerTest
    setup do
      @alice = users(:alice)
      @post = posts(:one)
    end

    test "succeeds for own post" do
      log_in_as(@alice)
      get edit_post_url(@post)
      assert_response :success
    end

    test "allows author to edit own unpublished post" do
      scheduled_post = posts(:scheduled)
      log_in_as(@alice)
      get edit_post_url(scheduled_post)
      assert_response :success
    end

    test "denies other users" do
      log_in_as(users(:bob))
      get edit_post_url(@post)
      assert_redirected_to posts_url
      assert_equal "You are not authorized to perform this action.", flash[:alert]
    end
  end

  class UpdateTest < PostsControllerTest
    setup do
      @alice = users(:alice)
      @post = posts(:one)
    end

    test "updates post" do
      travel_to Time.zone.parse("2025-10-15 12:00:00") do
        log_in_as(@alice)
        patch post_url(@post), params: { post: { body: @post.body, published_at: @post.published_at, slug: @post.slug, title: @post.title } }
        assert_redirected_to post_url(@post)
      end
    end

    test "denies other users" do
      log_in_as(users(:bob))
      patch post_url(@post), params: { post: { title: "Updated by Bob" } }
      assert_redirected_to posts_url
      assert_equal "You are not authorized to perform this action.", flash[:alert]
      @post.reload
      assert_not_equal "Updated by Bob", @post.title
    end
  end

  class DestroyTest < PostsControllerTest
    setup do
      @alice = users(:alice)
      @post = posts(:one)
    end

    test "destroys post" do
      log_in_as(@alice)
      assert_difference("Post.count", -1) do
        delete post_url(@post)
      end

      assert_redirected_to posts_url
    end

    test "denies other users" do
      log_in_as(users(:bob))
      assert_no_difference("Post.count") do
        delete post_url(@post)
      end
      assert_redirected_to posts_url
      assert_equal "You are not authorized to perform this action.", flash[:alert]
    end
  end
end
