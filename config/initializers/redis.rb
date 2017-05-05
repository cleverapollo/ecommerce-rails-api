class Redis
  def self.current
    @current ||= configure
  end

  private

  # Хз зачем было сделано так
  def self.configure
    redis_db = 0
    if SHARD_ID == '01'
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
end