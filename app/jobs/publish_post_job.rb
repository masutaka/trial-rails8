class PublishPostJob < ApplicationJob
  queue_as :default

  def perform(post_id, scheduled_at)
    post = Post.find_by(id: post_id)
    return unless post  # 記事が削除されている場合は静かに終了

    # 既に公開済みの場合はスキップ（冪等性）
    return if post.published

    # published_at が未来の場合はスキップ
    return if post.published_at.present? && post.published_at > Time.current

    # scheduled_at と現在の published_at が異なる場合はスキップ（公開日時が変更された or 取り消された）
    return if post.published_at.blank? || post.published_at.to_i != scheduled_at

    # 記事を公開
    post.update!(published: true)
  end
end
