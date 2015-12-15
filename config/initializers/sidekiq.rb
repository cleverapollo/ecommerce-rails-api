# In the future make redis database equal shard id
redis_db = [0,0,2][SHARD_ID.to_i]

Sidekiq.configure_server do |config|
  config.failures_max_count = 5000

  if Rails.env.staging?
    config.redis = { size: (ENV["CONCURRENCY"] || 20).to_i, url: "redis://localhost:6379/7", namespace: "rees46_api_#{ Rails.env }" }
  else
    config.redis = { size: (ENV["CONCURRENCY"] || 20).to_i, url: "redis://localhost:6379/#{ redis_db }", namespace: "rees46_api_#{ Rails.env }" }
  end
end

Sidekiq.configure_client do |config|
  if Rails.env.staging?
    config.redis = { size: (ENV["CONCURRENCY"] || 20).to_i, url: "redis://localhost:6379/7", namespace: "rees46_api_#{ Rails.env }" }
  else
    config.redis = { size: (ENV["CONCURRENCY"] || 20).to_i, url: "redis://localhost:6379/#{ redis_db }", namespace: "rees46_api_#{ Rails.env }" }
  end
end

module Sidekiq
  def self.full_reset
    Sidekiq::Queue.all.each(&:clear)
    Sidekiq.redis {|c| c.del('stat:processed') }
    Sidekiq.redis {|c| c.del('stat:failed') }
    Sidekiq::Stats.new.reset
    Sidekiq::RetrySet.new.clear
    Sidekiq::Failures.reset_failures
  end
end