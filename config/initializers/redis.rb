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
    if Rails.env.production?
      # На 01 шарде редис перенесен на сервер с крон тасками
      host = '88.99.193.211:7000'
    else
      host = 'localhost:6379'
    end
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
    if Rails.env.production?
      host = '144.76.156.6:6379'
    else
      host = 'localhost:6379'
    end
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
