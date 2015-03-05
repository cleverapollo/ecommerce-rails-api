module Recommender
  module Impl
    class Similar < Recommender::Weighted
      PRICE_UP = 1.25
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
            result = result.by_ca(gender)

            if item.custom_attributes['sizes'].try(:first).try(:present?)
              result = result.by_ca(sizes: item.custom_attributes['sizes'])
            end
          end
          result
        else
          super
        end
      end

      def items_to_weight
        price_range = ((item.price * PRICE_DOWN).to_i..(item.price * PRICE_UP).to_i)
        categories_for_query = params.categories.try(:any?) ? params.categories : item.categories
        min_date = 1.month.ago.to_date.to_time.to_i

        items_relation = items_to_recommend.where(price: price_range).in_categories(categories_for_query).where.not(id: item.id)
        if recommend_only_widgetable?
          items_relation = items_relation.merge(Item.widgetable)
        end

        result = shop.actions.where(item_id: items_relation).where('timestamp > ?', min_date).group(:item_id).by_average_rating.limit(LIMIT).pluck(:item_id)
        if result.size < LIMIT
          result += items_relation.where.not(id: result).limit(LIMIT - result.size).pluck(:id)
        end
        result
      end
    end
  end
end
