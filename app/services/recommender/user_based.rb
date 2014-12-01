module Recommender
  class UserBased < Base
    def recommended_ids
      ms = MahoutService.new
      ms.open

      result = if ms.tunnel && ms.tunnel.active?
        items_to_include = items_in_shop
        if recommend_only_widgetable?
          items_to_include = items_to_include.merge(Item.widgetable)
        end

        r = ms.user_based(params.user.id,
                      params.shop.id,
                      params.item_id,
                      include: items_to_include.pluck(:id),
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
