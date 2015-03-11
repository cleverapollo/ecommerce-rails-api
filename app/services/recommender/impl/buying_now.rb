module Recommender
  module Impl
    class BuyingNow < Recommender::Weighted
      LIMIT = 20

      def items_to_recommend
        if shop.sectoral_algorythms_available?
          result = super
          if shop.category.wear? && item.present?
            gender = SectoralAlgorythms::Wear::Gender.calculate_for(user, shop: shop, current_item: item)
            result = result.by_ca(gender: gender)
          end
          result
        else
          super
        end
      end

      def inject_promotions(result_ids)
        Promotion.find_each do |promotion|
          if promotion.show?(shop: shop, item: item)
            promoted_item_id = promotion.scope(items_to_recommend.in_categories(item.categories)).first.try(:id)
            if promoted_item_id.present?
              result_ids[0] = promoted_item_id
            end
          end
        end

        result_ids
      end

      def items_to_weight
        min_date = 1.day.ago.to_i

        all_items = items_to_recommend.where.not(id: excluded_items_ids)

        # Выводит топ товаров за последние сутки.
        # Те, что чаще покупаются - будут выше.
        # Если покупок нет, все равно будет работать.
        result = shop.actions.where('timestamp >= ?', min_date)
        result = result.where(item_id: all_items)
        result = result.group(:item_id)
        result = result.order('SUM(purchase_count) DESC, SUM(view_count) DESC')
        result = result.limit(LIMIT).pluck(:item_id)
        unless shop.strict_recommendations?
          result = inject_random_items(result)
        end
        result = inject_promotions(result)
        result
      end
    end
  end
end
