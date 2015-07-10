##
# Рекомендации, которые будут получены из махаута по user-user алгоритму
#
module Recommender
  class UserBased < Base
    # Переопределенный метод из базового класса. Накидываем сверху отраслевые алгоритмы
    def items_to_recommend
      if params.modification.present?
        result = super
        if params.modification == 'fashion'
          #gender = SectoralAlgorythms::Wear::Gender.value_for(user, shop: shop, current_item: item)
          #result = result.by_ca(gender: gender)

          # фильтрация по размерам одежды
          #if item && item.custom_attributes['sizes'].try(:first).try(:present?)
          #  result = result.by_ca(sizes: item.custom_attributes['sizes'])
          #end
        end
        result
      else
        super
      end
    end

    def recommended_ids

      excluded_items = excluded_items_ids

      ms = MahoutService.new(shop.brb_address)
      ms.open

      result = []

      while result.size<params.limit
        result = fetch_user_based(excluded_items, ms)
        break if result.empty?
        # уберем товары, которые не актуальные
        result = Item.where(id: result).pluck(:id, :widgetable).to_h.delete_if { |val| !val }.keys
        excluded_items = (excluded_items+result).compact.uniq
      end

      ms.close

      if result.size > params.limit
        result.take(params.limit)
      else
        result
      end
    end

    def fetch_user_based(excluded_items, ms)
      if ms.tunnel && ms.tunnel.active?
        # Коллаборативка в контексте текущего товара - как будто пользователь этот товар уже купил
        r = ms.user_based(params.user.id,
                          params.shop.id,
                          params.item_id,
                          include: [], # Махаут в курсе итемов
                          exclude: excluded_items,
                          limit: params.limit*2)

        if r.none?
          # Коллаборативка по истории действий пользователя
          r = ms.user_based(params.user.id,
                            params.shop.id,
                            nil,
                            include: [], # Махаут в курсе итемов
                            exclude: excluded_items,
                            limit: params.limit*2)
        end

        r
      else
        []
      end
    end
  end
end
