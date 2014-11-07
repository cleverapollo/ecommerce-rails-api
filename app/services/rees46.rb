class Rees46
  class << self
    def cookie_name
      'rees46_session_id'
    end

    def base_url
      if Rails.env.development?
        'http://127.0.0.1:8080'
      else
        'http://api.rees46.com'
      end
    end
  end
end
