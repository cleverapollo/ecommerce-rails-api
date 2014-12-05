module Recommender
  module Impl
    class AlsoBought < Recommender::Weighted
      LIMIT = 20

      def check_params!
        raise Recommendations::IncorrectParams.new('Item ID required for this recommender') if params.item.blank?
      end

      def items_to_weight
        return [] if items_which_cart_to_analyze.none?

        result = OrderItem.where('order_id IN (SELECT DISTINCT(order_id) FROM order_items WHERE item_id IN (?) limit 10)', items_which_cart_to_analyze)
        result = result.where.not(item_id: excluded_items_ids)
        result = result.joins(:item).merge(Item.recommendable.in_locations(locations))
        if recommend_only_widgetable?
          result = result.merge(Item.widgetable)
        end
        result = result.group(:item_id).order('COUNT(item_id) DESC').limit(LIMIT)
        result.pluck(:item_id)
      end

      def items_which_cart_to_analyze
        [item.id]
      end
    end
  end
end
