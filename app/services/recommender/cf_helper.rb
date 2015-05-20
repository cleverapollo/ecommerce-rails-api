# Модуль для вспомогательных функций коллаборативной фильтрации
module Recommender
  module CfHelper

    LIMIT_CF_ITEMS = 1000

    def cf_weight(i_w)
      cf_weighted = {}
      if i_w.any?
        ms = MahoutService.new
        ms.open
        cf_result = ms.item_based_weight(params.user.id,
                                         weight: i_w,
                                         limit: LIMIT_CF_ITEMS)
        ms.close

        # равномерно распределяем оценку по порядку, в котором махаут вернул результат
        # TODO: ориентироваться на оценку, выданную махаутом. а не на результат вычислений
        delta = 1.0/cf_result.size
        cur_cf_pref = 1.0
        cf_result.each do |cf_item|
          cf_weighted[cf_item] = (cur_cf_pref.to_f * 10000).to_i
          cur_cf_pref-=delta
        end
      end
      cf_weighted
    end
  end
end