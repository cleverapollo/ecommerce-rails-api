module Recommender
  class UserBased < Base
    def recommended_ids
      ms = MahoutService.new
      ms.open

      result = if ms.tunnel && ms.tunnel.active?
        r = ms.user_based(params.user.id,
                      params.shop.id,
                      params.item_id,
                      include: items_in_shop,
                      include: [],
                      exclude: excluded_items_ids,
                      limit: params.limit)

        if r.none?
          r = ms.user_based(params.user.id,
                      params.shop.id,
                      nil,
                      include: items_in_shop,
                      include: [],
                      exclude: excluded_items_ids,
                      limit: params.limit)
        end

        r
      else
        []
      end
      ms.close

      result
    end
  end
end
