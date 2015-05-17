module Recommender
  module Impl
    class Experiment < Recommender::Weighted
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

        # Находим отсортированные товары
        result = relation.where('sales_rate is not null and sales_rate > 0').order(sales_rate: :desc).limit(limit).pluck(:id)

        unless shop.strict_recommendations?
          # Если товаров недостаточно - рандом
          result = inject_random_items(result) unless in_category
        end

        # Добавляем продвижение брендов
        result = inject_promotions(result)

        result
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

    end
  end
end
