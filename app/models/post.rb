class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy

  scope :published, -> { where(published: true) }
  scope :scheduled, -> { where(published: false).where("published_at > ?", Time.current) }
  scope :draft, -> { where(published: false, published_at: nil) }
  scope :ready_to_publish, -> { where(published: false).where("published_at <= ?", Time.current) }

  def to_param
    slug
  end

  def scheduled?
    !published && published_at.present? && published_at > Time.current
  end

  def draft?
    !published && published_at.nil?
  end

  def previous_post(current_user = nil)
    scope = if current_user && user == current_user
              # 作成者が自分の記事を閲覧中: 自分の記事（Draft含む）から前後を取得
              Post.where(user: current_user)
    else
              # それ以外: 公開記事のみから前後を取得
              Post.published
    end

    scope.where("published_at < ?", published_at)
         .order(published_at: :desc)
         .first
  end

  def next_post(current_user = nil)
    scope = if current_user && user == current_user
              # 作成者が自分の記事を閲覧中: 自分の記事（Draft含む）から前後を取得
              Post.where(user: current_user)
    else
              # それ以外: 公開記事のみから前後を取得
              Post.published
    end

    scope.where("published_at > ?", published_at)
         .order(published_at: :asc)
         .first
  end
end
