# Модуль для вспомогательных функций коллаборативной фильтрации
module Recommender
  module WeightHelper

    LIMIT_CF_ITEMS = 100
    RATING_MULTIPLY = 3500

    def cf_weight(items_to_weight)
      cf_weighted = {}

      if shop.use_brb?

        if items_to_weight.any? && params.user
          ms = MahoutService.new(shop.brb_address)
          ms.open
          cf_result = ms.item_based_weight(params.user.id, shop.id,
                                           weight: items_to_weight,
                                           limit: LIMIT_CF_ITEMS)
          ms.close
          #  ориентироваться на оценку, выданную махаутом.
          cf_weighted = cf_result.map{|item| [item[:item], item[:rating].to_f * RATING_MULTIPLY]}.to_h

        end

      else

        cf_weighted = index_weight(items_to_weight)

      end


      cf_weighted
    end

    # равномерно распределяем оценку по порядку, в котором махаут вернул результат
    def index_weight(i_w)
      result = {}
      delta = 1.0/i_w.size
      cur_pref = 1.0
      i_w.each do |item|
        result[item] = (cur_pref.to_f * RATING_MULTIPLY).to_i
        cur_pref -= delta
      end
      result
    end

    def sr_weight(items)
      shop.items.where(id: items).pluck(:id, :sales_rate).to_h
    end

  end
end