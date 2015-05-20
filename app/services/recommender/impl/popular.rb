module Recommender
  module Impl
    class Popular < Recommender::Personalized

      K_SR = 1.0
      K_CF = 1.0

      def items_to_weight
        # Разные запросы в зависимости от присутствия или отсутствия категории
        # Используют разные индексы
        in_category = false
        relation = if categories.try(:any?)
                     in_category = true
                     popular_in_category
                   else
                     popular_in_all_shop
                   end

        # Находим отсортированные товары
        result = relation.where('sales_rate is not null and sales_rate > 0').order(sales_rate: :desc)
                     .limit(LIMIT_CF_ITEMS).pluck(:id)

        result
      end


      # @return Int[]
      def rescore(i_w, cf_weighted)
        # Взвешиваем по SR
        sr_weight(i_w).merge(cf_weighted) do |key, sr, cf|
          # подмешиваем оценку SR
          (K_SR*sr.to_f + K_CF*cf.to_f)/(K_CF+K_SR)
        end
      end



      # Популярные по всему магазину
      # @returns - ActiveRecord List of Action[]
      def popular_in_all_shop
        items_to_recommend.where.not(id: excluded_items_ids)
      end

      # Популярные в конкретной категории
      def popular_in_category
        popular_in_all_shop.in_categories(params.categories)
      end

      def sr_weight(items)
        shop.items.where(id: items).pluck(:id, :sales_rate).to_h
      end
    end
  end
end
