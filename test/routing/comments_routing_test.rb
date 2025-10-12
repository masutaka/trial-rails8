require "test_helper"

class CommentsRoutingTest < ActionDispatch::IntegrationTest
  test "routes to comments#create nested under posts" do
    assert_routing(
      { method: "post", path: "/posts/my-post-slug/comments" },
      { controller: "comments", action: "create", post_slug: "my-post-slug" }
    )
  end

  test "routes to comments#edit with shallow route" do
    assert_routing(
      { method: "get", path: "/comments/1/edit" },
      { controller: "comments", action: "edit", id: "1" }
    )
  end

  test "routes to comments#update with shallow route (PATCH)" do
    assert_routing(
      { method: "patch", path: "/comments/1" },
      { controller: "comments", action: "update", id: "1" }
    )
  end

  test "routes to comments#update with shallow route (PUT)" do
    assert_routing(
      { method: "put", path: "/comments/1" },
      { controller: "comments", action: "update", id: "1" }
    )
  end

  test "routes to comments#destroy with shallow route" do
    assert_routing(
      { method: "delete", path: "/comments/1" },
      { controller: "comments", action: "destroy", id: "1" }
    )
  end
end
