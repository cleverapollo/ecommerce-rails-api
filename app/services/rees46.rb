class Rees46
  COOKIE_NAME = 'rees46_session_id'
  SSID_NAME = 'ssid'
  HOST = Rails.env.production? ? WhiteLabel.api_domain : Rails.env.staging? ? 'stage.api.rees46.com' : '127.0.0.1:8080'
  USER_AGENT = 'REES46 Fetcher 1.0'

  class << self
    def site_url
      if Rails.env.production?
        'https://app.rees46.com'
      else
        Rails.env.staging? ? 'http://stage.rees46.com' : 'http://localhost:3000'
      end
    end

    def vendor_url
      if Rails.env.production?
        'https://vendor.rees46.com'
      else
        'http://localhost:3333'
      end
    end
  end
end
