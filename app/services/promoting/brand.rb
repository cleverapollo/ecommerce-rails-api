module Promoting
  class Brand

    class << self

      # Находит бренды, которые промоутируют этот товар
      # @param item Item
      # @return Advertiser[]
      def find_by_item(item, expansion_only)

        # Если бренд не определен, то ничего нет
        brand = item.brand
        return [] if brand.blank?

        # Если категории не в списке площадок для продвижения, то ничего нет
       advertisers_for_categories(item.shop_id, item.categories, expansion_only).where(downcase_brand:brand.downcase).pluck(:id).compact.uniq
      end

      def advertiser_for_item(item, expansion_only)

        # Если бренд не определен, то ничего нет
        brand = item.brand
        return nil if brand.blank?

        # Если категории не в списке площадок для продвижения, то ничего нет
        advertisers_for_categories(item.shop_id, item.categories, expansion_only).where(downcase_brand:brand.downcase).limit(1)[0]
      end

      def advertisers_for_categories(shop_id, categories, expansion_only)
        relation = Advertiser.active.prioritized
        relation = relation.expansion if expansion_only
        relation.where(id: AdvertiserItemCategory.where(item_category_id:
                                                              ItemCategory.where(shop_id: shop_id,external_id: categories).pluck(:id))
                                 .select('advertiser_id'))
      end

      def advertises_for_shop(shop, expansion_only)
        relation = Advertiser.active.prioritized
        relation = relation.expansion if expansion_only
        relation.where(id: AdvertiserShop.where(shop_id: shop).select('advertiser_id'))
      end

    end

  end
end
