# == Schema Information
#
# Table name: users
#
#  id              :bigint           not null, primary key
#  email_address   :string(255)      not null
#  password_digest :string(255)      not null
#  username        :string(255)      not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#  index_users_on_username       (username) UNIQUE
#
require "test_helper"

class UserTest < ActiveSupport::TestCase
  # username バリデーションテスト

  test "username が存在しない場合、無効であること" do
    user = User.new(email_address: "test@example.com", password: "password", username: nil)
    assert_not user.valid?
    assert_includes user.errors[:username], "can't be blank"
  end

  test "username が空文字の場合、無効であること" do
    user = User.new(email_address: "test@example.com", password: "password", username: "")
    assert_not user.valid?
    assert_includes user.errors[:username], "can't be blank"
  end

  test "username が3文字未満の場合、無効であること" do
    user = User.new(email_address: "test@example.com", password: "password", username: "ab")
    assert_not user.valid?
    assert_includes user.errors[:username], "is too short (minimum is 3 characters)"
  end

  test "username が30文字を超える場合、無効であること" do
    user = User.new(email_address: "test@example.com", password: "password", username: "a" * 31)
    assert_not user.valid?
    assert_includes user.errors[:username], "is too long (maximum is 30 characters)"
  end

  test "username が小文字英数字、ハイフン、アンダースコアのみの場合、有効であること" do
    valid_usernames = [ "abc", "test_user", "user-name", "user123", "a1_b2-c3" ]
    valid_usernames.each do |username|
      user = User.new(email_address: "test@example.com", password: "password", username: username)
      assert user.valid?, "#{username} は有効であるべきですが、無効と判定されました"
    end
  end

  test "username に大文字が含まれる場合、小文字に正規化されること" do
    user = User.new(email_address: "test@example.com", password: "password", username: "TestUser")
    assert user.valid?
    assert_equal "testuser", user.username
  end

  test "username に記号（ハイフン、アンダースコア以外）が含まれる場合、無効であること" do
    invalid_usernames = [ "test@user", "test.user", "test user", "test!user" ]
    invalid_usernames.each do |username|
      user = User.new(email_address: "test@example.com", password: "password", username: username)
      assert_not user.valid?, "#{username} は無効であるべきですが、有効と判定されました"
      assert_includes user.errors[:username], "is invalid"
    end
  end

  test "username が重複する場合、無効であること" do
    User.create!(email_address: "user1@example.com", password: "password", username: "testuser")
    user = User.new(email_address: "user2@example.com", password: "password", username: "testuser")
    assert_not user.valid?
    assert_includes user.errors[:username], "has already been taken"
  end

  test "username が大文字小文字のみ異なる場合、無効であること（一意性の大文字小文字を区別しない）" do
    User.create!(email_address: "user1@example.com", password: "password", username: "testuser")
    user = User.new(email_address: "user2@example.com", password: "password", username: "TestUser")
    assert_not user.valid?
    assert_includes user.errors[:username], "has already been taken"
  end

  test "username が小文字に正規化されること" do
    user = User.new(email_address: "test@example.com", password: "password", username: "TestUser")
    user.valid?
    assert_equal "testuser", user.username
  end
end
