# Модуль для вспомогательных функций коллаборативной фильтрации
module Recommender
  module WeightHelper

    LIMIT_CF_ITEMS = 1000
    RATING_MULTIPLY = 10000

    def cf_weight(i_w)
      cf_weighted = {}
      if i_w.any? && params.user
        ms = MahoutService.new
        ms.open
        cf_result = ms.item_based_weight(params.user.id,
                                         weight: i_w,
                                         limit: LIMIT_CF_ITEMS)
        ms.close

        # TODO: ориентироваться на оценку, выданную махаутом. а не на результат вычислений
        cf_weighted = cf_result.map{|item| [item[:item], item[:rating].to_f*RATING_MULTIPLY]}.to_h
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
        cur_pref-=delta
      end
      result
    end

    def sr_weight(items)
      shop.items.where(id: items).pluck(:id, :sales_rate).to_h
    end

  end
end