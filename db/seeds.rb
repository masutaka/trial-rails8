# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# ユーザーの作成
puts "Creating users..."
alice = User.find_or_create_by!(email_address: "alice@example.com") do |user|
  user.username = "alice"
  user.password = "password"
  user.password_confirmation = "password"
end

bob = User.find_or_create_by!(email_address: "bob@example.com") do |user|
  user.username = "bob"
  user.password = "password"
  user.password_confirmation = "password"
end

# 投稿の作成
puts "Creating posts..."

# 公開済み投稿（3件）
Post.find_or_create_by!(slug: "first-post") do |post|
  post.user = alice
  post.title = "最初の投稿"
  post.body = "これは最初の投稿です。Rails 8の学習を始めました。"
  post.published_at = 3.days.ago
  post.published = true
end

Post.find_or_create_by!(slug: "second-post") do |post|
  post.user = alice
  post.title = "2番目の投稿"
  post.body = "これは2番目の投稿です。Solid Queueを使った予約投稿機能が便利です。"
  post.published_at = 2.days.ago
  post.published = true
end

Post.find_or_create_by!(slug: "third-post") do |post|
  post.user = bob
  post.title = "3番目の投稿"
  post.body = "これは3番目の投稿です。Mission Control Jobsで非同期ジョブの監視ができます。"
  post.published_at = 1.day.ago
  post.published = true
end

# 予約投稿（1件）
Post.find_or_create_by!(slug: "scheduled-post") do |post|
  post.user = alice
  post.title = "予約投稿"
  post.body = "この投稿は未来の日時に公開予定です。"
  post.published_at = 1.day.from_now
  post.published = false
end

# 下書き（1件）
Post.find_or_create_by!(slug: "draft-post") do |post|
  post.user = alice
  post.title = "下書き投稿"
  post.body = "これは下書きです。まだ公開日時が設定されていません。"
  post.published_at = nil
  post.published = false
end

# コメントの作成
puts "Creating comments..."

first_post = Post.find_by(slug: "first-post")
second_post = Post.find_by(slug: "second-post")

if first_post
  Comment.find_or_create_by!(
    post: first_post,
    user: bob,
    body: "素晴らしい投稿ですね！"
  )

  Comment.find_or_create_by!(
    post: first_post,
    user: alice,
    body: "ありがとうございます！"
  )
end

if second_post
  Comment.find_or_create_by!(
    post: second_post,
    user: alice,
    body: "Solid Queueは本当に便利ですよね。"
  )
end

# 商品の作成
puts "Creating products..."

Product.find_or_create_by!(name: "商品A") do |product|
  product.inventory_count = 10
end

Product.find_or_create_by!(name: "商品B") do |product|
  product.inventory_count = 5
end

Product.find_or_create_by!(name: "商品C") do |product|
  product.inventory_count = 0
end

puts "Seeding completed!"
puts "Users: #{User.count}"
puts "Posts: #{Post.count}"
puts "Comments: #{Comment.count}"
puts "Products: #{Product.count}"
