require 'rollbar/rails'
Rollbar.configure do |config|
  config.access_token = '4899eb45828d4b62932213125ddf8a71'

  if Rails.env.development? or Rails.env.test?
    config.enabled = false
  end
end
