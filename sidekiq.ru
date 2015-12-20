require "rubygems"
require "sidekiq/web"

environment = ENV["RAILS_ENV"] || "development"

require "./config/environment"

unless environment == "development"
  use Rack::Auth::Basic do |username, password|
    username == "monitoring" && password == "xqs7mk93mS3op3W3K58r"
  end
end

run Sidekiq::Web