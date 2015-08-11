##
# Рекомендации, которые будут получены из махаута по user-user алгоритму
#
module Recommender
  class UserBased < Base

    def recommended_ids

      excluded_items = excluded_items_ids

      # при отправке тестового письма пользователь не может быть инициализирован, поэтому для него выдаем пустые рекомендации
      return [] unless params.user

      ms = MahoutService.new(shop.brb_address)
      ms.open

      result = []
      opposite_gender = SectoralAlgorythms::Wear::Gender.new(params.user).opposite_gender
      # ограничим количество итераций во избежании зацикливания
      iterations = 0
      while result.size<params.limit && iterations<3
        new_result = fetch_user_based(excluded_items, ms)
        break if new_result.empty?
        # По отраслевым отсеивать тут
        # уберем товары, которые не актуальные или не соответствуют полу
        new_result = Item.where(id: new_result).pluck(:id, :widgetable, :gender).delete_if { |val| !val[1] || val[2]==opposite_gender }.map { |v| v[0] }
        result = result+new_result
        excluded_items = (excluded_items+new_result).compact.uniq
        iterations+=1
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
                          params.item.id,
                          include: [], # Махаут в курсе итемов
                          exclude: excluded_items,
                          limit: params.limit*8)

        if r.none?
          # Коллаборативка по истории действий пользователя
          r = ms.user_based(params.user.id,
                            params.shop.id,
                            nil,
                            include: [], # Махаут в курсе итемов
                            exclude: excluded_items,
                            limit: params.limit*8)
        end

        r
      else
        []
      end
    end
  end
end
