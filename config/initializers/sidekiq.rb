# In the future make redis database equal shard id
redis_db = [0,0,2][SHARD_ID.to_i]

Sidekiq.configure_server do |config|
  config.failures_max_count = 5000

  if Rails.env.staging?
    config.redis = { url: "redis://localhost:6379/7", namespace: "rees46_api_#{ Rails.env }" }
  else
    config.redis = { url: "redis://localhost:6379/#{ redis_db }", namespace: "rees46_api_#{ Rails.env }" }
  end
end

Sidekiq.configure_client do |config|
  if Rails.env.staging?
    config.redis = { url: "redis://localhost:6379/7", namespace: "rees46_api_#{ Rails.env }" }
  else
    config.redis = { url: "redis://localhost:6379/#{ redis_db }", namespace: "rees46_api_#{ Rails.env }" }
  end
end
