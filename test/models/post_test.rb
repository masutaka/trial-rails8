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
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      published_posts = Post.published

      assert_includes published_posts, posts(:one)
      assert_includes published_posts, posts(:two)
      assert_not_includes published_posts, posts(:scheduled)
      assert_not_includes published_posts, posts(:draft)
      assert_not_includes published_posts, posts(:ready_to_publish)
    end
  end

  # scheduled スコープのテスト
  test "scheduled scope should return unpublished posts with future published_at" do
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      scheduled_posts = Post.scheduled

      assert_includes scheduled_posts, posts(:scheduled)
      assert_not_includes scheduled_posts, posts(:one)
      assert_not_includes scheduled_posts, posts(:two)
      assert_not_includes scheduled_posts, posts(:draft)
      assert_not_includes scheduled_posts, posts(:ready_to_publish)
    end
  end

  # draft スコープのテスト
  test "draft scope should return unpublished posts without published_at" do
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      draft_posts = Post.draft

      assert_includes draft_posts, posts(:draft)
      assert_not_includes draft_posts, posts(:one)
      assert_not_includes draft_posts, posts(:two)
      assert_not_includes draft_posts, posts(:scheduled)
      assert_not_includes draft_posts, posts(:ready_to_publish)
    end
  end

  # ready_to_publish スコープのテスト
  test "ready_to_publish scope should return unpublished posts with past or present published_at" do
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      ready_posts = Post.ready_to_publish

      assert_includes ready_posts, posts(:ready_to_publish)
      assert_not_includes ready_posts, posts(:one)
      assert_not_includes ready_posts, posts(:two)
      assert_not_includes ready_posts, posts(:scheduled)
      assert_not_includes ready_posts, posts(:draft)
    end
  end

  # scheduled? メソッドのテスト
  test "scheduled? should return true for scheduled posts" do
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      assert posts(:scheduled).scheduled?
      assert_not posts(:one).scheduled?
      assert_not posts(:draft).scheduled?
      assert_not posts(:ready_to_publish).scheduled?
    end
  end

  # draft? メソッドのテスト
  test "draft? should return true for draft posts" do
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      assert posts(:draft).draft?
      assert_not posts(:one).draft?
      assert_not posts(:scheduled).draft?
      assert_not posts(:ready_to_publish).draft?
    end
  end

  # previous_post メソッドのテスト
  test "previous_post should return previous post from author's posts when current_user is the author" do
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      alice = users(:alice)
      post = posts(:one)

      # Alice's posts には one, scheduled, draft が含まれる（published_at の順）
      previous = post.previous_post(alice)

      # previous_post は published_at が現在の記事より前の記事を返す（自分の記事のみ）
      assert_not_nil previous
      assert_equal alice, previous.user
    end
  end

  test "previous_post should return previous post from published posts only when current_user is not the author" do
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      bob = users(:bob)
      post = posts(:one)

      # Bob's perspective では公開記事のみが対象
      previous = post.previous_post(bob)

      # previous_post は公開記事の中から前の記事を返す
      if previous
        assert previous.published
      end
    end
  end

  test "previous_post should return previous post from published posts only when current_user is nil" do
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      post = posts(:one)

      # 未認証ユーザーは公開記事のみが対象
      previous = post.previous_post(nil)

      # previous_post は公開記事の中から前の記事を返す
      if previous
        assert previous.published
      end
    end
  end

  # next_post メソッドのテスト
  test "next_post should return next post from author's posts when current_user is the author" do
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      alice = users(:alice)
      post = posts(:alice_old_post)

      # Alice's posts から次の記事を取得
      next_post = post.next_post(alice)

      # next_post は published_at が現在の記事より後の記事を返す（自分の記事のみ）
      assert_not_nil next_post
      assert_equal alice, next_post.user
      assert_equal posts(:one), next_post
    end
  end

  test "next_post should return next post from published posts only when current_user is not the author" do
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      bob = users(:bob)
      post = posts(:alice_old_post)

      # Bob's perspective では公開記事のみが対象
      next_post = post.next_post(bob)

      # next_post は公開記事の中から次の記事を返す
      if next_post
        assert next_post.published
      end
    end
  end

  test "next_post should return next post from published posts only when current_user is nil" do
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      post = posts(:alice_old_post)

      # 未認証ユーザーは公開記事のみが対象
      next_post = post.next_post(nil)

      # next_post は公開記事の中から次の記事を返す
      if next_post
        assert next_post.published
      end
    end
  end

  # visible_to スコープのテスト
  test "visible_to should return published posts and user's unpublished posts when user is present" do
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      alice = users(:alice)
      visible_posts = Post.visible_to(alice)

      # 公開記事（全員分）
      assert_includes visible_posts, posts(:alice_old_post)
      assert_includes visible_posts, posts(:one)
      assert_includes visible_posts, posts(:two)

      # Alice の未公開記事
      assert_includes visible_posts, posts(:scheduled)
      assert_includes visible_posts, posts(:draft)

      # Bob の未公開記事は含まれない
      assert_not_includes visible_posts, posts(:ready_to_publish)
    end
  end

  test "visible_to should return only published posts when user is nil" do
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      visible_posts = Post.visible_to(nil)

      # 公開記事のみ
      assert_includes visible_posts, posts(:alice_old_post)
      assert_includes visible_posts, posts(:one)
      assert_includes visible_posts, posts(:two)

      # 未公開記事は含まれない
      assert_not_includes visible_posts, posts(:scheduled)
      assert_not_includes visible_posts, posts(:draft)
      assert_not_includes visible_posts, posts(:ready_to_publish)
    end
  end

  test "visible_to should not include other users' unpublished posts" do
    travel_to Time.zone.parse("2025-10-15 12:00:00") do
      bob = users(:bob)
      visible_posts = Post.visible_to(bob)

      # 公開記事（全員分）
      assert_includes visible_posts, posts(:alice_old_post)
      assert_includes visible_posts, posts(:one)
      assert_includes visible_posts, posts(:two)

      # Bob の未公開記事
      assert_includes visible_posts, posts(:ready_to_publish)

      # Alice の未公開記事は含まれない
      assert_not_includes visible_posts, posts(:scheduled)
      assert_not_includes visible_posts, posts(:draft)
    end
  end

  # viewable_by? メソッドのテスト
  test "viewable_by? should return true for published posts by anyone" do
    published_post = posts(:one)

    assert published_post.viewable_by?(nil), "未認証ユーザーでも公開記事は閲覧可能"
    assert published_post.viewable_by?(users(:alice)), "作成者は公開記事を閲覧可能"
    assert published_post.viewable_by?(users(:bob)), "他のユーザーも公開記事を閲覧可能"
  end

  test "viewable_by? should return true for unpublished posts by author" do
    draft_post = posts(:draft)
    alice = users(:alice)

    assert draft_post.viewable_by?(alice), "作成者は未公開記事を閲覧可能"
  end

  test "viewable_by? should return false for unpublished posts by non-author" do
    draft_post = posts(:draft)
    bob = users(:bob)

    assert_not draft_post.viewable_by?(bob), "他のユーザーは未公開記事を閲覧不可"
    assert_not draft_post.viewable_by?(nil), "未認証ユーザーは未公開記事を閲覧不可"
  end
end
