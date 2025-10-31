require "test_helper"

class FollowsRoutingTest < ActionDispatch::IntegrationTest
  test "routes to follows#create with user_username parameter" do
    assert_routing(
      { method: "post", path: "/users/alice/follow" },
      { controller: "follows", action: "create", user_username: "alice" }
    )
  end

  test "routes to follows#destroy with user_username parameter" do
    assert_routing(
      { method: "delete", path: "/users/alice/follow" },
      { controller: "follows", action: "destroy", user_username: "alice" }
    )
  end
end
