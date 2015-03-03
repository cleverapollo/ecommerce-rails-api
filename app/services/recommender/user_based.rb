module Recommender
  class UserBased < Base
    def items_to_recommend
      if shop.sectoral_algorythms_available?
        result = super
        if shop.category.wear?
          if item.present?
            if item.custom_attributes['gender'].present?
              result = result.by_ca(gender: item.custom_attributes['gender'])
            end
          end
        end
        result
      else
        super
      end
    end

    def recommended_ids
      ms = MahoutService.new
      ms.open

      result = if ms.tunnel && ms.tunnel.active?
        items_to_include = items_to_recommend
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
                      include: items_to_include.pluck(:id),
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
