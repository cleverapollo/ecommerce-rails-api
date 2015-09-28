##
# Персонализированный рекомендер.
# Персонализация производится через подмешивание весовой выдачи CF к весовой выдаче рекоммендера
#
module Recommender
  class Personalized < Recommender::Weighted

    include ItemInjector
    include WeightHelper

    def items_to_recommend
     super
    end


    # @return Int[]
    def recommended_ids
      # получим товары для взвешивания
      i_w = items_to_weight

      result = []

      if i_w.any?
        # Взвешиваем махаутом
        cf_weighted = cf_weight(i_w.keys)

        # Рассчитываем финальную оценку
        result = rescore(i_w, cf_weighted).sort do |x, y|
          # сортируем по вычисленной оценке
          x= x[1].to_i
          y= y[1].to_i
          y<=>x
        end
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
      raise NotImplementedError.new('This should be implemented in concrete recommender class')
    end
  end
end
