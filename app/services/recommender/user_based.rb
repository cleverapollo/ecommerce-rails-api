##
# Рекомендации, которые будут получены из махаута по user-user алгоритму
#
module Recommender
  class UserBased < Base

    def recommended_ids

      excluded_items = excluded_items_ids

      # при отправке тестового письма пользователь не может быть инициализирован, поэтому для него выдаем пустые рекомендации
      return [] unless params.user

      # Не лезем к BRB, если магазину запрещено его использовать
      return [] unless params.shop.use_brb?

      result = []

      ms = MahoutService.new(shop.brb_address)
      ms.open

      opposite_gender = SectoralAlgorythms::VirtualProfile::Gender.new(params.user.profile).opposite_gender
      # ограничим количество итераций во избежании зацикливания
      iterations = 0
      while result.size<params.limit && iterations<3
        new_result = fetch_user_based(excluded_items, ms)
        break if new_result.empty?
        # По отраслевым отсеивать тут
        if params.modification.present?
          if params.modification == 'fashion' || params.modification == 'cosmetic'
            # уберем товары, которые не актуальные или не соответствуют полу
            new_result = Item.widgetable.recommendable.where(id: new_result)

            gender_algo = SectoralAlgorythms::VirtualProfile::Gender.new(params.user.profile)
            new_result = gender_algo.modify_relation_with_rollback(new_result)
            # Если fashion - дополнительно фильтруем по размеру
            if params.modification == 'fashion'
              size_algo = SectoralAlgorythms::VirtualProfile::Size.new(params.user.profile)
              new_result = size_algo.modify_relation_with_rollback(new_result)
            end
            new_result = new_result.pluck(:id)
          end
        else
          # Отфильтруем, чтобы не попали товары, недоступные к показу, если есть
          new_result = Item.widgetable.recommendable.where(id: new_result).pluck(:id)
        end
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

      # Не лезем к BRB, если магазину запрещено его использовать
      return [] unless params.shop.use_brb?

      if ms.tunnel && ms.tunnel.active?
        # Коллаборативка в контексте текущего товара - как будто пользователь этот товар уже купил
        r = ms.user_based(params.user.id,
                          params.shop.id,
                          params.item_id,
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
