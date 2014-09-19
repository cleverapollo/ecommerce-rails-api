module Recommender
  module Impl
    class AlsoBought < Recommender::Weighted
      LIMIT = 20

      def check_params!
        raise ArgumentError.new('Item ID required for this recommender') if params.item.blank?
      end

      def excluded_items
        ids = []
        ids += Action.where('purchase_count > 0').where(user_id: params.user.id, repeatable: false).pluck(:item_id)
        ids += [params.item.id] if params.item.present?
        ids += params.cart_item_ids
        ids.uniq.compact
      end

      def excluded_items_query
        q = "item_id NOT IN (SELECT item_id FROM actions WHERE user_id = #{params.user.id} AND purchase_count > 0 AND repeatable = false)"

        if params.item.id.present?
          q += " AND item_id != #{params.item.id}"
        end

        if params.cart_item_ids.any?
          q += " AND item_id NOT IN (#{params.cart_item_ids.join(',')})"
        end

        q
      end

      def items_to_weight
        items = OrderItem.select('item_id')
                         .where('order_id IN (SELECT DISTINCT order_id FROM order_items WHERE item_id = ?)', params.item.id)
                         .where(excluded_items_query)
                         .in_locations(locations)
                         .group('item_id')
                         .order('count(item_id) desc')
                         .limit(LIMIT)

        items.map(&:item_id)
      end
    end
  end
end
