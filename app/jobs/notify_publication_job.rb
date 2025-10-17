class NotifyPublicationJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post

    # 記事の作成者以外の全ユーザーに通知を作成
    User.where.not(id: post.user_id).find_each do |user|
      Notification.create!(user: user, post: post, read: false)
    end
  end
end
