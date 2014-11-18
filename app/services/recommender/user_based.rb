module Recommender
  class UserBased < Base
    def recommended_ids
      ms = MahoutService.new
      ms.open

      result = if ms.tunnel && ms.tunnel.active?
        ms.user_based(params.user.id,
                      params.shop.id,
                      params.item_id,
                      include: items_in_shop,
                      include: [],
                      exclude: excluded_items_ids,
                      limit: params.limit)
      else
        []
      end
      ms.close

      result
    end
  end
end
