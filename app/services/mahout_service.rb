class MahoutService
  class << self
    def user_based(user_id, options)
      brb.user_based_block(user_id, options)
    end

    def item_based_weight(user_id, options)
      brb.item_based_weight_block(user_id, options)
    end

    def item_based_filter(user_id, options)
      brb.item_based_filter_block(user_id, options)
    end

    private

    def brb
      BrB::Tunnel.create(nil, 'brb://localhost:5555')
    end
  end
end
