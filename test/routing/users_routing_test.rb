require "test_helper"

class UsersRoutingTest < ActionDispatch::IntegrationTest
  test "routes to users#show with username parameter" do
    assert_routing(
      { method: "get", path: "/users/alice" },
      { controller: "users", action: "show", username: "alice" }
    )
  end
end
