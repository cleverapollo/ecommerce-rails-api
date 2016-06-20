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
      # @return BrandCampaign[]
      def brand_campaign_for_item(item, expansion_only)

        # Если бренд не определен, то ничего нет
        brand = item.brand_downcase
        return nil if brand.blank?

        # Если категории не в списке площадок для продвижения, то ничего нет
        brand_campaigns_for_categories(item.shop_id, item.category_ids, expansion_only).where(downcase_brand: brand).limit(1)[0]
      end




      def brand_campaigns_for_categories(shop_id, categories, expansion_only)
        relation = BrandCampaign.active.prioritized
        relation = relation.expansion if expansion_only
        relation.where(id: BrandCampaignItemCategory.where( item_category_id: ItemCategory.where(shop_id: shop_id,external_id: categories).pluck(:id) ).select('brand_campaign_id') )
      end

      def brand_campaigns_for_shop(shop, expansion_only)
        relation = BrandCampaign.active.prioritized
        relation = relation.expansion if expansion_only
        relation.where(id: BrandCampaignShop.where(shop_id: shop).select('brand_campaign_id'))
      end

    end

  end
end
