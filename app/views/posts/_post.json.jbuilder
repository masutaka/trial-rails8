json.extract! post, :id, :user_id, :title, :body, :published_at, :slug, :created_at, :updated_at
json.url post_url(post, format: :json)
