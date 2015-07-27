module Promoting
  class Brand

    class << self

      # Находит бренды, которые промоутируют этот товар
      # @param item Item
      # @return Advertiser[]
      def find_by_item(item)

        # Если бренд не определен, то ничего нет
        brand = item.brand
        return [] if brand.blank?

        # Если категории не в списке площадок для продвижения, то ничего нет
       advertisers_for_categories(item.shop_id, item.categories).where(downcase_brand:brand.downcase).pluck(:id).compact.uniq
      end

      def advertisers_for_categories(shop_id, categories)
        Advertiser.active.prioritized.where(id: AdvertiserItemCategory.where(item_category_id:
                                                              ItemCategory.where(shop_id: shop_id,external_id: categories).pluck(:id))
                                 .select('advertiser_id'))
      end

      def advertises_for_shop(shop)
        Advertiser.active.prioritized.where(id: AdvertiserShop.where(shop_id: shop).select('advertiser_id'))
      end

    end

  end
end
