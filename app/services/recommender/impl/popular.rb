module Recommender
  module Impl
    class Popular < Recommender::Weighted
      LIMIT = 20

      def category_query
        if params.category_uniqid.present?
          "AND (array['#{params.category_uniqid}']::VARCHAR[] <@ items.categories)"
        elsif params.categories.present? && params.categories.any?
          "AND (array[#{params.categories.map{|c| "'#{c}'" }.join(',')}]::VARCHAR[] <@ items.categories)"
        end
      end

      def min_date
        3.month.ago.to_date.to_time.to_i
      end

      def items_in_category_query
        "
          SELECT items.id FROM items WHERE
          items.shop_id = #{params.shop.id}
          #{category_query}
        "
      end

      def items_to_weight
        res = Action.connection.execute("
          SELECT item_id
          FROM actions
          WHERE
            item_id IN (#{items_in_category_query})
            AND timestamp > #{min_date}
            AND shop_id = #{params.shop.id}
            #{item_query}
            #{locations_query}
            AND purchase_count > 0
          GROUP BY item_id
          ORDER BY SUM(purchase_count) DESC
          LIMIT #{LIMIT}
        ").map{|i| i['item_id'].to_i }

        if res.none? 
          res = Action.connection.execute("
            SELECT item_id
            FROM actions
            WHERE
              item_id IN (#{items_in_category_query})
              AND timestamp > #{min_date}
              AND shop_id = #{params.shop.id}
              #{item_query}
              #{locations_query}
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
