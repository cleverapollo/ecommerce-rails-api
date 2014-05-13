module Recommender
  module Impl
    class BuyingNow < Recommender::Weighted
      LIMIT = 20

      def excluded_query
        ids = []
        ids += Action.where('purchase_count > 0').where(user_id: params.user.id, repeatable: false).pluck(:item_id)
        ids += [params.item.id] if params.item.present?
        ids += params.cart_item_ids
        ids.uniq.compact

        if ids.any?
          "AND item_id NOT IN (#{ids.join(',')})"
        else
          ''
        end
      end

      def min_date
        1.day.ago.to_i
      end

      def items_to_weight
        Action.connection.execute("
          SELECT item_id
          FROM actions
          WHERE
            timestamp > #{min_date}
            AND shop_id = #{params.shop.id}
            #{locations_query}
            #{excluded_query}
            AND rating >= 4.2
            AND is_available = true
          GROUP BY item_id
          ORDER BY SUM(rating) DESC
          LIMIT #{LIMIT}
        ").map{|i| i['item_id'].to_i }
      end
    end
  end
end
