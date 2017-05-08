require "rubygems"
require "sidekiq/web"

environment = ENV["RAILS_ENV"] || "development"

require "./config/environment"

redis_db = 0
if SHARD_ID == '01'
  # На 01 шарде редис перенесен на сервер с крон тасками
  host = '88.99.193.211:7000'
else
  host = 'localhost:6379'
end
Sidekiq.configure_client do |config|
  config.redis = { url: "redis://#{host}/#{ redis_db }", namespace: "rees46_api_#{ Rails.env }" }
end

unless environment == "development"
  use Rack::Auth::Basic do |username, password|
    username == "monitoring" && password == "xqs7mk93mS3op3W3K58r"
  end
end

run Sidekiq::Web