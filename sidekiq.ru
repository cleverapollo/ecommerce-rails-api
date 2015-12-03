require "rubygems"
require "sidekiq/web"

environment = ENV["RAILS_ENV"] || "development"

require "./config/environment"

unless environment == "development"
  use Rack::Auth::Basic do |username, password|
    username == "admin" && password == "admin"
  end
end

run Sidekiq::Web