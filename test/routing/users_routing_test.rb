require "test_helper"

class UsersRoutingTest < ActionDispatch::IntegrationTest
  test "routes to users#show with username parameter" do
    assert_routing(
      { method: "get", path: "/users/alice" },
      { controller: "users", action: "show", username: "alice" }
    )
  end

  test "routes to users#following with username parameter" do
    assert_routing(
      { method: "get", path: "/users/alice/following" },
      { controller: "users", action: "following", username: "alice" }
    )
  end

  test "routes to users#followers with username parameter" do
    assert_routing(
      { method: "get", path: "/users/alice/followers" },
      { controller: "users", action: "followers", username: "alice" }
    )
  end
end
