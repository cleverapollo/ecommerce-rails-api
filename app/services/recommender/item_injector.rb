# Модуль для хранения методов финального изменения выдачи
module Recommender
  module ItemInjector

    MAX_PROMOTIONS = 3
    PLACES_FOR_PROMO = 1

    def categories_for_promo
      params.categories.try(:any?) ? params.categories : nil
    end

    def inject_promotions(result_ids)
      return result_ids if result_ids.empty?
      promotions_placed = 0
      in_categories = !categories_for_promo.nil? && categories_for_promo.try(:any?)

      if in_categories
        advertisers_list = Promoting::Brand.advertisers_for_categories(shop.id, categories_for_promo)
      else
        advertisers_list = Promoting::Brand.advertises_for_shop(shop.id)
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
          index_to_replace = promotions_placed
          result_ids.delete_at(cur_promo_index)
          result_ids.insert(index_to_replace, promoted_item_id)
          promotions_placed+=1
        else
          # не нашли, получаем из полной выборки
          if in_categories
            promoted_item_id = advertiser.first_in_categories(shop, categories_for_promo, excluded_items_ids)
          else
            promoted_item_id = advertiser.first_in_shop(shop, excluded_items_ids)
          end

          if promoted_item_id.present?
            result_ids.insert(promotions_placed, promoted_item_id)
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