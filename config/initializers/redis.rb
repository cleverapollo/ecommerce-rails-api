class Redis
  def self.current
    @current ||= configure
  end

  private

  # Хз зачем было сделано так
  def self.configure
    redis_db = 0
    begin
      Redis.new({
        url: "redis://localhost:6379/#{ redis_db }",
        namespace: "rees46_api_#{ Rails.env }"
      })
    rescue
      Redis.new({
        url: "redis://localhost:6379/#{ redis_db }",
        namespace: "rees46_api_#{ Rails.env }"
      })
    end
  end
end