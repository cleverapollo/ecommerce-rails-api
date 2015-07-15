##
# Рекомендации, которые будут получены из махаута по user-user алгоритму
#
module Recommender
  class UserBased < Base

    def recommended_ids

      excluded_items = excluded_items_ids

      ms = MahoutService.new(shop.brb_address)
      ms.open

      result = []
      opposite_gender = SectoralAlgorythms::Wear::Gender.new(params.user).opposite_gender
      while result.size<params.limit
        result = fetch_user_based(excluded_items, ms)
        break if result.empty?
        # По отраслевым отсеивать тут
        # уберем товары, которые не актуальные или не соответствуют полу
        result = Item.where(id: result).pluck(:id, :widgetable, :gender).delete_if { |val| !val[1] || val[2]==opposite_gender }.map{|v| v[0]}
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
