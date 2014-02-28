class MahoutService
  class << self
    def recommendations(user_id, options = {})
      brb.recommend_block(user_id, options)
    end

    private

    def brb
      BrB::Tunnel.create(nil, 'brb://localhost:5555')
    end
  end
end
