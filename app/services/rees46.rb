class Rees46
  COOKIE_NAME = 'rees46_session_id'
  HOST = Rails.env.production? ? 'api.rees46.com' : Rails.env.staging? ? 'stage.api.rees46.com' : '127.0.0.1:8080'
  TEAM_EMAIL = 'team@rees46.com'

  class << self
    def site_url
      Rails.env.production? ? 'http://rees46.com' : Rails.env.staging? ? 'http://stage.rees46.com' : 'http://localhost:3000'
    end
  end
end
