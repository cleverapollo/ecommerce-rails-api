class Redis
  def self.current
    @current ||= configure
  end

  def self.rtb
    @rtb ||= configure_rtb
  end


  private

  # Хз зачем было сделано так
  def self.configure
    redis_db = 0
    host = Rails.application.secrets.redis_host
    begin
      Redis.new({
        url: "redis://#{host}/#{ redis_db }",
        namespace: "rees46_api_#{ Rails.env }"
      })
    rescue
      Redis.new({
        url: "redis://#{host}/#{ redis_db }",
        namespace: "rees46_api_#{ Rails.env }"
      })
    end
  end


  def self.configure_rtb
    redis_db = 0
    host = Rails.application.secrets.redis_rtb_host
    begin
      Redis.new({
                    url: "redis://#{host}/#{ redis_db }",
                    namespace: ""
                })
    rescue
      Redis.new({
                    url: "redis://#{host}/#{ redis_db }",
                    namespace: ""
                })
    end
  end

end
