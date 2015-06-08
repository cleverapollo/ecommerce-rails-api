# Модуль для хранения методов финального изменения выдачи
module Recommender
  module ItemInjector

    MAX_PROMOTIONS = 1
    PLACES_FOR_PROMO = 3

    def inject_promotions(result_ids)
      promotions_placed = 0
      category_inner_ids = ItemCategory.where(external_id: categories).pluck(:id)
      if categories.nil?
        advertisers_list = Promoting::Brand.advertises_for_shop(shop)
      else
        advertisers_list = Promoting::Brand.advertisers_for_categories(category_inner_ids)
      end
      advertisers_list.each do |advertiser|
        # проверяем места на занятость
        break if promotions_placed>=MAX_PROMOTIONS

        # Выбрали рекламодателя
        # @todo: Приоритет выбора рекламодателя

        promoted_item_id = advertiser.first_in_selection(result_ids)

        if promoted_item_id.present?
          # нашли, вставляем на одно из первых мест
          cur_promo_index = result_ids.index(promoted_item_id)
          index_to_replace = cur_promo_index % PLACES_FOR_PROMO
          result_ids.delete_at(cur_promo_index)
          result_ids.insert(index_to_replace, promoted_item_id)
          promotions_placed+=1
        else
          # не нашли, получаем из полной выборки
          if categories.any?
            promoted_item_id = advertiser.first_in_categories(category_inner_ids)
          else
            promoted_item_id = advertiser.first_in_shop(shop)
          end
          if promoted_item_id.present?
            result_ids.insert(promoted_item_id % PLACES_FOR_PROMO, promoted_item_id)
            promotions_placed+=1
          end
        end

        # Считаем просмотр для бернда
        if promoted_item_id.present?
          BrandLogger.track_view(advertiser.id)
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