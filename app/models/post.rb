class Post < ApplicationRecord
  belongs_to :user

  def to_param
    slug
  end
end
