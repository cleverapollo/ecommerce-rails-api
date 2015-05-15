module Recommender
  module Impl
    class Popular < Recommender::Weighted
      LIMIT = 20

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

      def inject_promotions(result_ids)
        Promotion.find_each do |promotion|
          if promotion.show?(shop: shop, item: item, categories: categories)
            promoted_item_id = promotion.scope(items_to_recommend.in_categories(categories)).where.not(id: result_ids).limit(1).first.try(:id)
            if promoted_item_id.present?
              result_ids[0] = promoted_item_id
            end
          end
        end

        result_ids
      end

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

        result = by_purchases(relation, limit)
        # Если недобрали достаточно товаров по покупкам - дополняем товарами по рейтингу
        if result.size < limit
          result += by_rating(relation, limit - result.size, result)
        end

        unless shop.strict_recommendations?
          # Если уж и так недостаточно - рандом
          result = inject_random_items(result) unless in_category
        end

        result = inject_promotions(result)

        result
      end

      # Общие условия, работают для всех типов выборок
      def common_relation(relation)
        relation.where('timestamp > ?', 3.month.ago.to_date.to_time.to_i)
                .group(:item_id)
      end

      # Популярные по всему магазину
      def popular_in_all_shop
        all_items = items_to_recommend.where.not(id: excluded_items_ids)

        common_relation(shop.actions.where(item_id: all_items))
      end

      # Популярные в конкретной категории
      def popular_in_category
        items_in_category = items_to_recommend.where.not(id: excluded_items_ids)
        items_in_category = items_in_category.in_categories(params.categories)

        common_relation(shop.actions.where(item_id: items_in_category))
      end

      # Расчет по количеству покупок (для нормальных магазинов)
      def by_purchases(relation, limit = LIMIT)
        relation.where('purchase_count > 0').order('SUM(purchase_count) DESC')
                .limit(limit).pluck(:item_id)
      end

      # Расчет по рейтингу (для маленьких магазинов)
      def by_rating(relation, limit = LIMIT, given_ids)
        relation.order('SUM(rating) DESC').where.not(item_id: given_ids)
                .limit(limit).pluck(:item_id)
      end
    end
  end
end
