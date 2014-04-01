module Recommender
  module Impl
    class SeeAlso < Recommender::Weighted
      LIMIT = 20

      def shared_orders
        OrderItem.where(item_id: params.cart_item_ids).pluck(:order_id)
      end

      def excluded_items
        ids = []
        ids += Action.where('purchase_count > 0').where(user_id: params.user.id).pluck(:item_id)
        ids += params.cart_item_ids
        ids += [params.item.id] if params.item.present?
        ids.uniq.compact
      end

      def items_to_weight
        items = OrderItem.select('item_id')
                         .where('order_id IN (?)', shared_orders)
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
