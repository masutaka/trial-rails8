class Post < ApplicationRecord
  belongs_to :user

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
