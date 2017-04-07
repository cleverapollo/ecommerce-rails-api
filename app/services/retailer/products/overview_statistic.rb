module Retailer
  module Products
    class OverviewStatistic

      attr_accessor :shop,
                    :total, :recommendable, :widgetable, :ignored, :industrial,
                    :is_fashion, :is_cosmetic, :is_fmcg, :is_child,
                    :fashion_with_gender, :fashion_with_gender_and_sizes,
                    :child_with_gender, :child_with_age, :child_with_type, :child_with_age_and_type,
                    :cosmetic_gender, :cosmetic_hypoallergenic, :cosmetic_periodic, :cosmetic_for_skin, :cosmetic_for_hair,
                    :fmcg_hypoallergenic, :fmcg_periodic,
                    :child_fashion, :child_cosmetic, :child_fmcg

      def initialize(shop, extended = false)
        @shop = shop
        self.total = Item.where(shop_id: @shop.id).count
        self.recommendable = Item.where(shop_id: @shop.id).recommendable.count
        self.widgetable = Item.where(shop_id: @shop.id).recommendable.widgetable.count
        self.ignored = Item.where(shop_id: @shop.id).where(ignored: true).count
        self.industrial = Item.where(shop_id: @shop.id).where('is_fashion IS TRUE OR is_child IS TRUE OR is_cosmetic IS TRUE OR is_fmcg IS TRUE OR is_auto IS TRUE OR is_pets = true').recommendable.count

        if extended
          self.is_fashion = Item.where(shop_id: @shop.id).where('is_fashion').available.recommendable.widgetable.count
          self.is_child = Item.where(shop_id: @shop.id).where('is_child').available.recommendable.widgetable.count
          self.is_cosmetic = Item.where(shop_id: @shop.id).where('is_cosmetic').available.recommendable.widgetable.count
          self.is_fmcg = Item.where(shop_id: @shop.id).where('is_fmcg').available.recommendable.widgetable.count

          self.fashion_with_gender = Item.where(shop_id: @shop.id).where('is_fashion and fashion_gender is not null').available.recommendable.widgetable.count
          self.fashion_with_gender_and_sizes = Item.where(shop_id: @shop.id).where('is_fashion and fashion_gender is not null and fashion_sizes is not null').available.recommendable.widgetable.count

          self.child_with_gender = Item.where(shop_id: @shop.id).where('is_child and child_gender is not null').available.recommendable.widgetable.count
          self.child_with_age = Item.where(shop_id: @shop.id).where('is_child and (child_age_min is not null or child_age_max is not null)').available.recommendable.widgetable.count
          self.child_with_type = Item.where(shop_id: @shop.id).where('is_child and child_type is not null').available.recommendable.widgetable.count
          self.child_with_age_and_type = Item.where(shop_id: @shop.id).where('is_child and (child_age_min is not null or child_age_max is not null) and child_type is not null').available.recommendable.widgetable.count

          self.cosmetic_gender = Item.where(shop_id: @shop.id).where('is_cosmetic and cosmetic_gender is not null').available.recommendable.widgetable.count
          self.cosmetic_hypoallergenic = Item.where(shop_id: @shop.id).where('is_cosmetic and cosmetic_hypoallergenic is true').available.recommendable.widgetable.count
          self.cosmetic_periodic = Item.where(shop_id: @shop.id).where('is_cosmetic and cosmetic_periodic is true').available.recommendable.widgetable.count
          self.cosmetic_for_skin = Item.where(shop_id: @shop.id).where('is_cosmetic and (cosmetic_skin_part is not null or cosmetic_skin_type is not null or cosmetic_skin_condition is not null)').available.recommendable.widgetable.count
          self.cosmetic_for_hair = Item.where(shop_id: @shop.id).where('is_cosmetic and (cosmetic_hair_type is not null or cosmetic_hair_condition is not null)').available.recommendable.widgetable.count

          self.fmcg_hypoallergenic = Item.where(shop_id: @shop.id).where('is_fmcg and fmcg_hypoallergenic is true').available.recommendable.widgetable.count
          self.fmcg_periodic = Item.where(shop_id: @shop.id).where('is_fmcg and fmcg_periodic is true').available.recommendable.widgetable.count

          self.child_fashion = Item.where(shop_id: @shop.id).where('is_child and is_fashion').available.recommendable.widgetable.count
          self.child_cosmetic = Item.where(shop_id: @shop.id).where('is_child and is_cosmetic').available.recommendable.widgetable.count
          self.child_fmcg = Item.where(shop_id: @shop.id).where('is_child and is_fmcg').available.recommendable.widgetable.count
        end
      end

    end
  end
end
