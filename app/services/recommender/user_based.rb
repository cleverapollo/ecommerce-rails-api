##
# Рекомендации, которые будут получены из махаута по user-user алгоритму
#
module Recommender
  class UserBased < Base

    # Переопределенный метод из базового класса. Накидываем сверху отраслевые алгоритмы
    def items_to_recommend
      if shop.sectoral_algorythms_available?
        result = super
        if shop.category.wear?
          gender = SectoralAlgorythms::Wear::Gender.calculate_for(user, shop: shop, current_item: item)
          result = result.by_ca(gender: gender)

          # TODO: отбрасывать товары, которые явно не подходят по размеру
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

        # Коллаборативка в контексте текущего товара - как будто пользователь этот товар уже купил
        r = ms.user_based(params.user.id,
                      params.shop.id,
                      params.item_id,
                      include: items_to_include.pluck(:id),
                      exclude: excluded_items_ids,
                      limit: params.limit)

        if r.none?
          # Коллаборативка по истории действий пользователя
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
