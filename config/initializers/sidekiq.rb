# In the future make redis database equal shard id
redis_db = [0,0,2][SHARD_ID.to_i]

Sidekiq.configure_server do |config|
  config.redis = { size: (ENV["CONCURRENCY"] || 20).to_i, url: "redis://localhost:6379/#{redis_db}", namespace: "rees46_api_#{Rails.env}" }
end

Sidekiq.configure_client do |config|
  config.redis = { size: (ENV["CONCURRENCY"] || 20).to_i, url: "redis://localhost:6379/#{redis_db}", namespace: "rees46_api_#{Rails.env}" }
end
