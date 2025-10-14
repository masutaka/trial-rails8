class Post < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy

  scope :published, -> { where(published: true) }
  scope :scheduled, -> { where(published: false).where("published_at > ?", Time.current) }

  def to_param
    slug
  end

  def previous_post
    Post.where("published_at < ?", published_at)
        .order(published_at: :desc)
        .first
  end

  def next_post
    Post.where("published_at > ?", published_at)
        .order(published_at: :asc)
        .first
  end
end
