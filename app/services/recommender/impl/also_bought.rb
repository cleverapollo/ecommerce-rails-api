module Recommender
  module Impl
    class AlsoBought < Recommender::Weighted
      LIMIT = 20

      def check_params
        params.item.present?
      end

      def shared_orders
        OrderItem.where(item_id: params.item.id).pluck(:order_id)
      end

      def excluded_items
        ids = []
        ids += Action.where('purchase_count > 0').where(user_id: params.user.id).pluck(:item_id)
        ids += [params.item.id] if params.item.present?
        ids += params.cart_item_ids
        ids.uniq.compact
      end

      def items_to_weight
        items = OrderItem.select('item_id')
                         .where('order_id IN (?)', shared_orders)
                         .where('item_id NOT IN (?)', excluded_items)
                         .group('item_id')
                         .order('count(item_id) desc')
                         .limit(LIMIT)

        items.map(&:item_id)
      end
    end
  end
end
