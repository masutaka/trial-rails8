require "test_helper"

class NotificationsRoutingTest < ActionDispatch::IntegrationTest
  test "routes PATCH /notifications/:id/mark_as_read to notifications#mark_as_read" do
    assert_routing(
      { method: "patch", path: "/notifications/1/mark_as_read" },
      { controller: "notifications", action: "mark_as_read", id: "1" }
    )
  end

  test "routes PATCH /notifications/mark_all_as_read to notifications#mark_all_as_read" do
    assert_routing(
      { method: "patch", path: "/notifications/mark_all_as_read" },
      { controller: "notifications", action: "mark_all_as_read" }
    )
  end
end
