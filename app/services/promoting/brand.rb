module Promoting
  class Brand

    class << self

      # Находит бренды, которые промоутируют этот товар
      # @param item Item
      # @return BrandCampaign[]
      def find_by_item(item, expansion_only)

        # Если бренд не определен, то ничего нет
        brand = item.brand_downcase
        return [] if brand.blank?

        # Если категории не в списке площадок для продвижения, то ничего нет
       brand_campaigns_for_categories(item.shop_id, item.category_ids, expansion_only).where(downcase_brand:brand.downcase).pluck(:id).compact.uniq
      end


      # Определяет рекламные кампании, подходящие к указанному товару.
      # То есть кампании, соответствующие категории товара.
      # Используется только в рекомендере Similar
      # @param item [Item]
      # @param expansion_only [Boolean]
      # @return BrandCampaign::ActiveRecord_Relation
      def brand_campaign_for_item(item, expansion_only)

        # Если бренд не определен, то ничего нет
        brand = item.brand_downcase
        return nil if brand.blank?

        # Если категории не в списке площадок для продвижения, то ничего нет
        brand_campaigns_for_categories(item.shop_id, item.category_ids, expansion_only).where(downcase_brand: brand).limit(1)[0]
      end



      # Возвращает список рекламных кампаний бренда, соответствующих категориям или настроенным на любые категории
      # @param shop_id [Integer]
      # @param categories [String[]] Массив идентификаторов категорий со стороны магазина
      # @param expansion_only [Boolean]
      # @return BrandCampaign::ActiveRecord_Relation
      def brand_campaigns_for_categories(shop_id, categories, expansion_only)
        relation = BrandCampaign.active.prioritized
        relation = relation.expansion if expansion_only
        ids_by_categories = BrandCampaignItemCategory.where( item_category_id: ItemCategory.where(shop_id: shop_id, external_id: categories).pluck(:id) ).pluck(:brand_campaign_id).uniq
        relation.where('in_all_categories IS TRUE OR id IN (?)', ids_by_categories)
      end

      # Рекламные кампании брендов, действующие в магазине.
      # @param shop [Shop]
      # @param expansion_only [Boolean]
      # @return BrandCampaign::ActiveRecord_Relation
      def brand_campaigns_for_shop(shop, expansion_only)
        relation = BrandCampaign.active.prioritized
        relation = relation.expansion if expansion_only
        relation.where(id: BrandCampaignShop.where(shop_id: shop.id).select('brand_campaign_id'))
      end

    end

  end
end
