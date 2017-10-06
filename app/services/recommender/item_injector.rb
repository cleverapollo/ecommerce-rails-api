# Модуль для хранения методов финального изменения выдачи
module Recommender
  module ItemInjector

    MAX_PROMOTIONS = 3
    PROMO_FOR_CATEGORY = 1
    PLACES_FOR_PROMO = 1

    def categories_for_promo
      params.categories.try(:any?) ? params.categories : nil
    end


    # Вставляет продвигаемые товары
    def inject_promotions(result_ids, expansion_only = false)
      return result_ids if result_ids.empty?
      promotions_placed = 0

      # Ищем подходящий инвентарь в магазине
      shop_inventories = shop.shop_inventories.recommendations.includes(:vendor_campaigns)
      currencies = Currency.all

      catch :done do
        Rails.logger.debug '[PROMOTION START] ***'.magenta if Rails.env.development?

        shop_inventories.each do
        # @type [ShopInventory] shop_inventory
        |shop_inventory|

          # Проходим по списку кампаний
          shop_inventory.vendor_campaigns.each do
          # @type [VendorCampaign] vendor_campaign
          |vendor_campaign|

            # Берем валюту из массива
            vendor_campaign.currency = currencies.select {|c| c.id == vendor_campaign.currency_id }.first
            shop_inventory.currency = currencies.select {|c| c.id == shop_inventory.currency_id }.first

            # Проверяем чтобы минимальная ставка была меньше максимальной ставки вендора (конвертируем в одинаковые валюты)
            if shop_inventory.min_cpc_price <= vendor_campaign.currency.recalculate_to(shop_inventory.currency, vendor_campaign.max_cpc_price)
              # проверяем места на занятость
              throw :done if promotions_placed >= MAX_PROMOTIONS

              # Достаем подходящий товар
              promoted_item_id, promoted_uniqid = vendor_campaign.first_in_selection(result_ids, params.discount)

              if promoted_item_id.present?
                # нашли, вставляем на одно из первых мест
                cur_promo_index = result_ids.index(promoted_item_id)
                index_to_replace = promotions_placed
                result_ids.delete_at(cur_promo_index)
                result_ids.insert(index_to_replace, promoted_item_id)
                promotions_placed += 1
              else
                promoted_item_id, promoted_uniqid = vendor_campaign.first_in_shop(excluded_items_ids + result_ids, params.discount)
                if promoted_item_id.present?
                  result_ids.insert(promotions_placed, promoted_item_id)
                  # удаляем последний элемент, для созранения лимита
                  result_ids.pop
                  promotions_placed += 1
                end
              end

              # Считаем просмотр для бренда
              if promoted_item_id.present?
                vendor_campaign.track_view(params, promoted_uniqid)
              end

            end
          end

        end
      end
      Rails.logger.debug '[PROMOTION END] ***'.magenta if Rails.env.development?

      return result_ids



      # @deprecated больше не используется, выходит раньше
      in_categories = !categories_for_promo.nil? && categories_for_promo.try(:any?)

      if in_categories
        brand_campaigns_list = Promoting::Brand.brand_campaigns_for_categories(shop.id, categories_for_promo, expansion_only)
      else
        brand_campaigns_list = Promoting::Brand.brand_campaigns_for_shop(shop, expansion_only)
      end

      brand_campaigns_list.each do |brand_campaign|
        # проверяем места на занятость
        break if promotions_placed >= MAX_PROMOTIONS || (in_categories && promotions_placed >= PLACES_FOR_PROMO)

        # Выбрали рекламодателя
        # @todo: Приоритет выбора рекламодателя

        promoted_item_id = brand_campaign.first_in_selection(result_ids, params.discount)

        if promoted_item_id.present?
          # нашли, вставляем на одно из первых мест
          cur_promo_index = result_ids.index(promoted_item_id)
          index_to_replace = promotions_placed
          result_ids.delete_at(cur_promo_index)
          result_ids.insert(index_to_replace, promoted_item_id)
          promotions_placed += 1
        else
          # не нашли, получаем из полной выборки
          if in_categories
            promoted_item_id = brand_campaign.first_in_categories(shop, categories_for_promo, excluded_items_ids, params.discount, @strict_categories)
          else
            promoted_item_id = brand_campaign.first_in_shop(shop, excluded_items_ids, params.discount)
          end

          if promoted_item_id.present?
            result_ids.insert(promotions_placed, promoted_item_id)
            # удаляем последний элемент, для созранения лимита
            result_ids.pop
            promotions_placed += 1
          end
        end

        # Считаем просмотр для бренда
        if promoted_item_id.present?
          BrandLogger.track_view(brand_campaign.id, shop.id, params.type)
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
      inject_promotions(result, false)
    end
  end
end
