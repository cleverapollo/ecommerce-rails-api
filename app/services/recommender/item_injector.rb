# Модуль для хранения методов финального изменения выдачи
module Recommender
  module ItemInjector

    MAX_PROMOTIONS = 1
    PLACES_FOR_PROMO = 3

    def inject_promotions(result_ids)
      promotions_placed = 0
      Promotion.find_each do |promotion|
        # проверяем места на занятость
        break if promotions_placed>=MAX_PROMOTIONS

        if promotion.show?(shop: shop, item: item, categories: categories)
          # пытаемся найти промо в товарах, отданных рекоммендеру
          promoted_item_id = promotion.get_from_selection(result_ids)

          if promoted_item_id.present?
            # нашли, вставляем на одно из первых мест
            cur_promo_index = result_ids.index(promoted_item_id)
            index_to_replace = cur_promo_index % PLACES_FOR_PROMO
            result_ids.delete_at(cur_promo_index)
            result_ids.insert(index_to_replace, promoted_item_id)
            promotions_placed+=1
          else
            # не нашли, получаем из полной выборки
            promoted_item_id = promotion.scope(items_to_recommend).limit(1).first.try(:id)
            if promoted_item_id.present?
              result_ids.insert(promoted_item_id % PLACES_FOR_PROMO, promoted_item_id)
              promotions_placed+=1
            end
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