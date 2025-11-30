# == Schema Information
#
# Table name: comments
# Database name: primary
#
#  id         :bigint           not null, primary key
#  body       :text(65535)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  post_id    :bigint           not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_comments_on_post_id  (post_id)
#  index_comments_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (post_id => posts.id) ON DELETE => cascade
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class Comment < ApplicationRecord
  belongs_to :post, counter_cache: true
  belongs_to :user

  validates :body, presence: true, length: { minimum: 1, maximum: 10000 }

  # 作成時のリアルタイムブロードキャスト: コメントを追加 + コメント数を更新
  after_create_commit do
    broadcast_append_to post,
                        target: "comments",
                        partial: "comments/comment",
                        locals: { comment: self, allow_actions: false }
    broadcast_replace_to post,
                         target: "comment_count_#{post.id}",
                         partial: "posts/comment_count",
                         locals: { post: post }
    broadcast_replace_to [ post, user ],
                         target: ActionView::RecordIdentifier.dom_id(self),
                         partial: "comments/comment",
                         locals: { comment: self, allow_actions: true }
  end

  # 更新時のリアルタイムブロードキャスト: コメントを置き換え
  after_update_commit do
    broadcast_replace_to post,
                         partial: "comments/comment",
                         locals: { comment: self, allow_actions: false }
    broadcast_replace_to [ post, user ],
                         target: ActionView::RecordIdentifier.dom_id(self),
                         partial: "comments/comment",
                         locals: { comment: self, allow_actions: true }
  end

  # 削除時のリアルタイムブロードキャスト: コメントを削除 + コメント数を更新
  after_destroy_commit do
    broadcast_remove_to post
    broadcast_replace_to post,
                         target: "comment_count_#{post.id}",
                         partial: "posts/comment_count",
                         locals: { post: post }
  end
end
