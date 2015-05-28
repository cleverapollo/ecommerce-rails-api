# Модуль для хранения методов финального изменения выдачи
module Recommender
  module ItemInjector
    def inject_promotions(result_ids)
      Promotion.find_each do |promotion|
        if promotion.show?(shop: shop, item: item, categories: categories)
          promoted_item_id = promotion.scope(items_to_recommend.in_categories(categories)).where.not(id: result_ids+[item.id]).limit(1).first.try(:id)
          if promoted_item_id.present?
            result_ids[0] = promoted_item_id
          end
        end
      end

      result_ids
    end

    def inject_items(result)
      if result.size < params.limit && !shop.strict_recommendations?
        # Если товаров недостаточно - рандом
        result = inject_random_items(result)
      end

      # Добавляем продвижение брендов
      inject_promotions(result)
    end
  end
end