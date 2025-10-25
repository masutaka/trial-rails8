# == Schema Information
#
# Table name: follows
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  followed_id :bigint           not null
#  follower_id :bigint           not null
#
# Indexes
#
#  index_follows_on_followed_id                  (followed_id)
#  index_follows_on_follower_id                  (follower_id)
#  index_follows_on_follower_id_and_followed_id  (follower_id,followed_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (followed_id => users.id) ON DELETE => cascade
#  fk_rails_...  (follower_id => users.id) ON DELETE => cascade
#
require "test_helper"

class FollowTest < ActiveSupport::TestCase
  test "should not allow duplicate follow" do
    follow = Follow.new(
      follower: users(:alice),
      followed: users(:bob)
    )
    assert_not follow.valid?
    assert_includes follow.errors[:follower_id], "has already been taken"
  end

  test "should not allow user to follow themselves" do
    follow = Follow.new(
      follower: users(:alice),
      followed: users(:alice)
    )
    assert_not follow.valid?
    assert_includes follow.errors[:followed_id], "cannot follow yourself"
  end
end
