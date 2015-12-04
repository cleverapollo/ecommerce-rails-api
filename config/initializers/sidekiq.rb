# In the future make redis database equal shard id
redis_db = [0,0,2][SHARD_ID.to_i]

if Rails.env.staging?
  Redis.current ||= Redis.new({ url: "redis://localhost:6379/7", namespace: "rees46_api_#{Rails.env}" })
else
  Redis.current ||= Redis.new({ url: "redis://localhost:6379/#{redis_db}", namespace: "rees46_api_#{Rails.env}" })
end

Sidekiq.configure_server do |config|
  config.redis = Redis.current
end

Sidekiq.configure_client do |config|
  config.redis = Redis.current
end
