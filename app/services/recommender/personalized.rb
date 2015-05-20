##
# Персонализированный рекомендер.
# Персонализация производится через подмешивание весовой выдачи CF к весовой выдаче рекоммендера
#
module Recommender
  class Personalized < Recommender::Weighted

    include ItemInjector
    include CfHelper

    LIMIT = 20

    K_SR = 1.0
    K_CF = 1.0

    def items_to_recommend
      if shop.sectoral_algorythms_available?
        result = super
        if shop.category.wear?
          gender = SectoralAlgorythms::Wear::Gender.calculate_for(user, shop: shop)
          result = result.by_ca(gender: gender)
          # TODO: фильтрация по размерам одежды
        end
        result

      else
        super
      end
    end


    # @return Int[]
    def recommended_ids
      # получим товары для взвешивания
      i_w = items_to_weight

      # Взвешиваем махаутом
      cf_weighted = cf_weight(i_w)


      # Взвешиваем по SR
      sr_weighted = sr_weight(i_w)
      # sr_weighted.merge(cf_weighted) do |key, sr, cf|
      #  (K_SR*sr.to_f + K_CF*cf.to_f)/(K_CF+K_SR)
      #  end

      # Рассчитываем финальную оценку
      result = rescore(i_w, cf_weighted).sort do |x, y|
        # сортируем по вычисленной оценке
        x= x[1].to_i
        y= y[1].to_i
        y<=>x
      end

      # Ограничиваем размер вывода
      result = if result.size > params.limit
                 result.take(params.limit)
               else
                 result
               end

      # оставим только id товаров
      result = result.to_h.keys

      inject_items(result)
    end

    def rescore(i_w, cf_weighted)
      cf_weighted
    end
  end
end
