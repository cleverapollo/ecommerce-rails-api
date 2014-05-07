module Recommender
  module Impl
    class AlsoBought < Recommender::Weighted
      LIMIT = 20

      def check_params
        params.item.present?
      end

      def excluded_items
        ids = []
        ids += Action.where('purchase_count > 0').where(user_id: params.user.id, repeatable: false).pluck(:item_id)
        ids += [params.item.id] if params.item.present?
        ids += params.cart_item_ids
        ids.uniq.compact
      end

      def items_to_weight
        items = OrderItem.select('item_id')
                         .where('order_id IN (SELECT DISTINCT order_id FROM order_items WHERE item_id = ?)', params.item.id)
                         .where('item_id NOT IN (?)', excluded_items)
                         .group('item_id')
                         .order('count(item_id) desc')
                         .limit(LIMIT)

        items = items.where(locations_clause) if params.locations.present?

        items.map(&:item_id)
      end
    end
  end
end
