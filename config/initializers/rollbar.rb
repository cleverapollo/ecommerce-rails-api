require 'rollbar/rails'
Rollbar.configure do |config|
  config.access_token = '8b197bc247a844278f109dbd06ad2e66'

  if Rails.env.development? || Rails.env.test?
    config.enabled = false
  end

  config.exception_level_filters.merge!('ActionController::RoutingError' => 'ignore')
end
