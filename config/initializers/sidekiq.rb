Sidekiq.configure_server do |config|
  redis_port = ENV.fetch("REDIS_PORT") { 6379 }
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:#{redis_port}/0") }
end

Sidekiq.configure_client do |config|
  redis_port = ENV.fetch("REDIS_PORT") { 6379 }
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:#{redis_port}/0") }
end
