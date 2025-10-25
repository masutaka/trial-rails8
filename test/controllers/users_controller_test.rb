require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "ユーザーが存在する場合、ユーザーページが正常に表示されること" do
    user = users(:alice)
    get user_path(user.username)
    assert_response :success
  end

  test "ユーザーが存在しない場合、404 エラーが返されること" do
    get user_path("nonexistent")
    assert_response :not_found
  end
end
