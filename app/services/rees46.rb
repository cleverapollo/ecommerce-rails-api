class Rees46
  COOKIE_NAME = 'rees46_session_id'
  SSID_NAME = 'ssid'
  HOST = Rails.env.production? ? 'api.rees46.com' : Rails.env.staging? ? 'stage.api.rees46.com' : '127.0.0.1:8080'

  class << self
    def site_url
      if Rails.env.production?
        'https://app.rees46.com'
      else
        Rails.env.staging? ? 'http://stage.rees46.com' : 'http://localhost:3000'
      end
    end
  end
end
