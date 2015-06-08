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
        advertisers = advertisers_for_categories(item.categories)
        return [] if advertisers.empty?

        # Вернем ид рекламодателей, промоутирующих данный бренд
        Advertiser.where(id: advertisers, downcase_brand: brand.downcase)
      end

      def advertisers_for_categories(categories)
        AdvertiserItemCategory.where(item_category_id: categories).pluck(:advertiser_id).compact.uniq
      end

      def advertises_for_shop(shop)
        AdvertiserShop.where(shop_id:shop)
      end

    end

  end
end
