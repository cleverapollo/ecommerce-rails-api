require 'rollbar/rails'
Rollbar.configure do |config|
  config.access_token = Rails.application.secrets.rollbar_access_token

  if Rails.env.development? || Rails.env.test?
    config.enabled = false
  end

  config.exception_level_filters.merge!('ActionController::RoutingError' => 'ignore')
end

Sidekiq.configure_server do |config|
  config.error_handlers << Proc.new {|ex,ctx_hash| Rollbar.error(ex, ctx_hash) }
end
