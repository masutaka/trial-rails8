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

  test "ユーザーが存在する場合、following ページが正常に表示されること" do
    user = users(:alice)
    get following_user_path(user.username)
    assert_response :success
    assert_select "h1", "#{user.username} がフォロー中"
  end

  test "ユーザーが存在しない場合、following ページで 404 エラーが返されること" do
    get following_user_path("nonexistent")
    assert_response :not_found
  end

  test "ユーザーが存在する場合、followers ページが正常に表示されること" do
    user = users(:alice)
    get followers_user_path(user.username)
    assert_response :success
    assert_select "h1", "#{user.username} のフォロワー"
  end

  test "ユーザーが存在しない場合、followers ページで 404 エラーが返されること" do
    get followers_user_path("nonexistent")
    assert_response :not_found
  end
end
