##
# Рекомендации, которые будут получены из махаута по user-user алгоритму
#
module Recommender
  class UserWeighted < Base

    include Recommender::SectoralAlgorythms

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

      if result.size < params.limit
        # Рассчет весов
        i_w = items_to_weight
        delta = params.limit-result.size

        # if i_w.any?
        #   ms = MahoutService.new
        #   ms.open
        #   result = ms.item_based_weight(params.user.id,
        #                                 weight: i_w,
        #                                 limit: params.limit)
        #   ms.close
        # end

        result += if i_w.size > delta
                   i_w.sample(delta)
                 else
                   i_w
                 end

        result
      end

      result
    end
  end
end
