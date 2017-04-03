# In the future make redis database equal shard id
require 'sidekiq/middleware/i18n'
redis_db = 0

Sidekiq.configure_server do |config|
  config.failures_max_count = 5000

  if Rails.env.staging?
    config.redis = { size: (ENV["CONCURRENCY"] || 20).to_i, url: "redis://localhost:6379/7", namespace: "rees46_api_#{ Rails.env }" }
  else
    config.redis = { size: (ENV["CONCURRENCY"] || 60).to_i, url: "redis://localhost:6379/#{ redis_db }", namespace: "rees46_api_#{ Rails.env }" }
  end

  Rails.application.config.after_initialize do
    ActiveRecord::Base.connection_pool.disconnect!

    ActiveSupport.on_load(:active_record) do
      config = Rails.application.config.database_configuration[Rails.env]
      config['reaping_frequency'] = 10 # seconds
      config['pool'] = Sidekiq.options[:concurrency].to_i + 1
      ActiveRecord::Base.establish_connection(config)

      Rails.logger.info("Connection Pool size for Sidekiq Server is now: #{ActiveRecord::Base.connection.pool.instance_variable_get('@size')}")
    end
  end
end

Sidekiq.configure_client do |config|
  if Rails.env.staging?
    config.redis = { size: (ENV["CONCURRENCY"] || 20).to_i, url: "redis://localhost:6379/7", namespace: "rees46_api_#{ Rails.env }" }
  else
    config.redis = { size: (ENV["CONCURRENCY"] || 60).to_i, url: "redis://localhost:6379/#{ redis_db }", namespace: "rees46_api_#{ Rails.env }" }
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
