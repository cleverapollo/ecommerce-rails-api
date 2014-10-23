module Recommender
  module Impl
    class Popular < Recommender::Weighted
      LIMIT = 20

      def items_to_weight
        # Разные запросы в зависимости от присутствия или отсутствия категории
        # Используют разные индексы
        relation = if categories.try(:any?)
          popular_in_category
        else
          popular_in_all_shop
        end

        result = by_purchases(relation).sample(limit)
        # Если недобрали достаточно товаров по покупкам - дополняем товарами по рейтингу
        if result.size < limit
          result += by_rating(relation, limit - result.size)
        end

        # Если уж и так недостаточно - рандом
        result = inject_random_items(result)
      end

      # Общие условия, работают для всех типов выборок
      def common_relation(relation)
        relation.where('timestamp > ?', 3.month.ago.to_date.to_time.to_i)
                .group(:item_id)
      end

      # Популярные по всему магазину
      def popular_in_all_shop
        common_relation(shop.actions.where.not(item_id: excluded_items_ids).available)
      end

      # Популярные в конкретной категории
      def popular_in_category
        items_in_category = shop.items.available.where.not(id: excluded_items_ids)
        items_in_category = items_in_category.in_categories(params.categories)

        common_relation(shop.actions.where(item_id: items_in_category))
      end

      # Расчет по количеству покупок (для нормальных магазинов)
      def by_purchases(relation, limit = LIMIT)
        relation.where('purchase_count > 0').order('SUM(purchase_count) DESC')
                .limit(LIMIT).pluck(:item_id)
      end

      # Расчет по рейтингу (для маленьких магазинов)
      def by_rating(relation, limit = LIMIT)
        relation.order('SUM(rating) DESC')
                .limit(limit).pluck(:item_id)
      end
    end
  end
end
