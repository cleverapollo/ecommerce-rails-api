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

        ms.user_based(params.user.id,
                      params.shop.id,
                      params.item_id,
                      include: items_to_include.pluck(:id),
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
