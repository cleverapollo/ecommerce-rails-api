module Recommender
  module Impl
    class Similar < Recommender::Weighted
      LARGE_PRICE_UP = 1.5
      PRICE_UP = 1.25
      LARGE_PRICE_DOWN = 0.5
      PRICE_DOWN = 0.85
      LIMIT = 20

      def check_params!
        raise Recommendations::IncorrectParams.new('Item ID required for this recommender') if params.item.blank?
        raise Recommendations::IncorrectParams.new('That item has no price') if params.item.price.blank?
      end

      def items_to_recommend
        if shop.sectoral_algorythms_available?
          result = super
          if shop.category.wear?
            gender = SectoralAlgorythms::Wear::Gender.calculate_for(user, shop: shop, current_item: item)
            result = result.by_ca(gender: gender)

            if item.custom_attributes['sizes'].try(:first).try(:present?)
              result = result.by_ca(sizes: item.custom_attributes['sizes'])
            end
          end
          result
        else
          super
        end
      end

      def inject_promotions(result_ids)
        Promotion.find_each do |promotion|
          if promotion.show?(shop: shop, item: item)
            promoted_item_id = promotion.scope(items_relation).where.not(id: result_ids).limit(1).first.try(:id)
            if promoted_item_id.present?
              result_ids[0] = promoted_item_id
            end
          end
        end

        result_ids
      end

      def price_range
        (item.price * PRICE_DOWN).to_i..(item.price * PRICE_UP).to_i
      end

      def large_price_range
        (item.price * LARGE_PRICE_DOWN).to_i..(item.price * LARGE_PRICE_UP).to_i
      end

      def categories_for_query
        categories.try(:any?) ? categories : item.categories
      end

      def min_date
        1.month.ago.to_date.to_time.to_i
      end

      def items_relation
        items_to_recommend.in_categories(categories_for_query).where.not(id: item.id).order('price DESC').limit(limit * 3)
      end

      def items_relation_with_price_condition
        items_relation.where(price: price_range)
      end

      def items_relation_with_larger_price_condition
        items_relation.where(price: large_price_range)
      end

      def items_to_weight
        result = shop.actions.where(item_id: items_relation_with_price_condition).where('timestamp > ?', min_date).group(:item_id).by_average_rating.limit(limit).pluck(:item_id)
        if result.size < limit
          result += items_relation_with_larger_price_condition.where.not(id: result).limit(limit - result.size).pluck(:id)
        end

        result = inject_promotions(result)

        result
      end
    end
  end
end
