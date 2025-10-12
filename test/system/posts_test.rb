require "application_system_test_case"

class PostsTest < ApplicationSystemTestCase
  # setup do
  #   @alice = users(:alice)
  #   @bob = users(:bob)
  #   @post = posts(:one)
  # end
  #
  # def log_in_as(user)
  #   visit new_session_url
  #   fill_in "email_address", with: user.email_address
  #   fill_in "password", with: "password"
  #   click_on "Sign in"
  #   assert_text "Log out"
  # end
  #
  # test "visiting the index" do
  #   visit posts_url
  #   assert_selector "h1", text: "Posts"
  # end
  #
  # test "author can create, update and destroy their post" do
  #   log_in_as(@alice)
  #   slug = "test-post"
  #
  #   # Create
  #   visit posts_url
  #   click_on "New post"
  #
  #   fill_in "Title", with: "New Test Post"
  #   fill_in "Body", with: "Test body content"
  #   fill_in "Published at", with: @post.published_at
  #   fill_in "Slug", with: slug
  #   click_on "Create Post"
  #
  #   assert_text "Post was successfully created"
  #   save_screenshot("tmp/screenshots/aaa.png")
  #
  #   # Update
  #   visit edit_post_url(slug)
  #   save_screenshot("tmp/screenshots/bbb.png")
  #   assert_selector "h1", text: "Editing post"
  #   fill_in "Body", with: ""
  #   fill_in "Body", with: "Updated body content"
  #   save_screenshot("tmp/screenshots/ccc.png")
  #   click_on "Update Post"
  #   save_screenshot("tmp/screenshots/ddd.png")
  #
  #   assert_text "Post was successfully updated"
  #
  #   # # Destroy
  #   # accept_confirm do
  #   #   click_on "Destroy this post"
  #   # end
  #   #
  #   # assert_text "Post was successfully destroyed"
  # end
  #
  # # test "should not allow non-author to update Post" do
  # #   log_in_as(@bob)
  # #   visit post_url(@post)
  # #
  # #   assert_no_text "Edit this post"
  # #   assert_no_text "Destroy this post"
  # # end
end
