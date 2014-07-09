module Recommender
  module Impl
    class Popular < Recommender::Weighted
      LIMIT = 20

      def category_query
        if params.category_uniqid.present?
          "AND category_uniqid = '#{params.category_uniqid}'"
        end
      end

      def min_date
        3.month.ago.to_date.to_time.to_i
      end

      def items_to_weight
        res = Action.connection.execute("
          SELECT item_id
          FROM actions
          WHERE
            timestamp > #{min_date}
            AND shop_id = #{params.shop.id}
            #{category_query}
            #{item_query}
            #{locations_query}
            AND purchase_count > 0
            AND is_available = true
          GROUP BY item_id
          ORDER BY SUM(purchase_count) DESC
          LIMIT #{LIMIT}
        ").map{|i| i['item_id'].to_i }

        if res.none? 
          res = Action.connection.execute("
            SELECT item_id
            FROM actions
            WHERE
              timestamp > #{min_date}
              AND shop_id = #{params.shop.id}
              #{category_query}
              #{item_query}
              #{locations_query}
              AND is_available = true
            GROUP BY item_id
            ORDER BY SUM(rating) DESC
            LIMIT #{LIMIT}
          ").map{|i| i['item_id'].to_i }
        end

        res
      end
    end
  end
end
