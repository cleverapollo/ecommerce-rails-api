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
        advertisers = advertisers_list(item.categories)
        return [] if advertisers.empty?

        interested_advertisers = Advertiser.where(downcase_brand: brand.downcase)



        # Находим рекламодателей, которые:
        # 1. Работают с магазином, где продается это товар
        # 2. Продвигатся в категории, где лежит этот товар
        # 3. Их бренд равен бренду товара

        # Мне не хватает:
        # 1. Привязки магазинов к рекламодателям
        # 2. Привязки категорий к рекламодателям
        # 3. Понимания, как сопоставить бренд-рекламодатель и товар бренда.

        []

      end

      def advertisers_list(categories)
        AdvertiserItemCategory.where(item_category_id: categories).pluck(:advertiser_id).compact.uniq
      end

    end

  end
end
