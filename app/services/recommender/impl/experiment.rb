module Recommender
  module Impl
    class Experiment < Recommender::Impl::Popular

      def items_to_weight
        # Разные запросы в зависимости от присутствия или отсутствия категории
        # Используют разные индексы
        in_category = false
        relation = if categories.try(:any?)
                     in_category = true
                     popular_in_category
                   else
                     # Выбираем товары только из уникальных категорий (для главной страницы)
                     popular_in_all_shop.select("DISTINCT ON (items.categories) items.*, items.id, items.sales_rate ").order(categories: :asc)
                   end

        # Находим отсортированные товары
        # Не делать pluck! ( иначе вернется больше итемов чем надо, баг ActiveRecord(?))
        result = relation.where('sales_rate is not null and sales_rate > 0').order(sales_rate: :desc)
                     .limit(LIMIT_CF_ITEMS)

        # Преобразуем result к виду {id=>weight}
        result.to_a.map{|value| [value.id,value.sales_rate]}.to_h
      end


      # @return Int[]
      def rescore(items_weighted, cf_weighted)
        puts cf_weighted.inspect
        items_weighted.merge(cf_weighted) do |key, sr, cf|
          # подмешиваем оценку SR
          (K_SR*sr.to_f + K_CF*cf.to_f)/(K_CF+K_SR)
        end
      end


    end
  end
end
