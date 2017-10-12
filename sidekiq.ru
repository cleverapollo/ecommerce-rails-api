require "rubygems"
require "sidekiq/web"

environment = ENV["RAILS_ENV"] || "development"

require "./config/environment"

redis_db = 0
host = Rails.application.secrets.redis_host
Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{host}/#{ redis_db }", namespace: "rees46_api_#{ Rails.env }" }
end

unless environment == "development"
  use Rack::Auth::Basic do |username, password|
    username == "monitoring" && password == "xqs7mk93mS3op3W3K58r"
  end
end

run Sidekiq::Web
