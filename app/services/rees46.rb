class Rees46
  class << self
    def cookie_name
      'rees46_session_id'
    end

    def host
      if Rails.env.production?
        'api.rees46.com'
      else
        '127.0.0.1:8080'
      end
    end
  end
end
