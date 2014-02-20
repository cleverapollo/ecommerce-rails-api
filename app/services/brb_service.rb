class BrbService
  class << self

    def recommend(user_id)
      service.recommend_block(user_id)
    end

    private

    def service
      BrB::Tunnel.create(nil, 'brb://localhost:5555')
    end

  end
end
