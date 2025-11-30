# == Schema Information
#
# Table name: posts
# Database name: primary
#
#  id             :bigint           not null, primary key
#  body           :text(65535)
#  comments_count :integer          default(0), not null
#  published      :boolean          default(FALSE), not null
#  published_at   :datetime
#  slug           :string(255)
#  title          :string(255)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_posts_on_published                   (published)
#  index_posts_on_published_and_published_at  (published,published_at)
#  index_posts_on_published_at                (published_at)
#  index_posts_on_user_id                     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id) ON DELETE => cascade
#
class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :notifications, as: :notifiable, dependent: :destroy

  scope :published, -> { where(published: true) }
  scope :scheduled, -> { where(published: false).where("published_at > ?", Time.current) }
  scope :draft, -> { where(published: false, published_at: nil) }
  scope :ready_to_publish, -> { where(published: false).where("published_at <= ?", Time.current) }
  scope :visible_to, ->(user) {
    if user
      where(published: true).or(where(published: false, user: user))
    else
      published
    end
  }

  after_commit :schedule_publication, on: [ :create, :update ], if: :should_schedule_publication?
  after_commit :notify_all_users, on: [ :create, :update ], if: :just_published?

  def to_param
    slug
  end

  def scheduled?
    !published && published_at.present? && published_at > Time.current
  end

  def draft?
    !published && published_at.nil?
  end

  def viewable_by?(user)
    published || (user && self.user == user)
  end

  def previous_post(current_user = nil)
    navigation_scope(current_user)
      .where("published_at < ?", published_at)
      .order(published_at: :desc)
      .first
  end

  def next_post(current_user = nil)
    navigation_scope(current_user)
      .where("published_at > ?", published_at)
      .order(published_at: :asc)
      .first
  end

  def just_published?
    saved_change_to_published? && published?
  end

  private

  def navigation_scope(current_user)
    if current_user && user == current_user
      # 作成者が自分の記事を閲覧中: 自分の記事（Draft含む）から前後を取得
      Post.where(user: current_user)
    else
      # それ以外: 公開記事のみから前後を取得
      Post.published
    end
  end

  def should_schedule_publication?
    published_at.present? && !published
  end

  def schedule_publication
    scheduled_at = published_at.to_i

    if published_at > Time.current
      # 未来の日時の場合は遅延実行
      PublishPostJob.set(wait_until: published_at).perform_later(id, scheduled_at)
    else
      # 過去または現在の日時の場合は即座に実行
      PublishPostJob.perform_later(id, scheduled_at)
    end
  end

  def notify_all_users
    NotifyPublicationJob.perform_later(id)
  end
end
