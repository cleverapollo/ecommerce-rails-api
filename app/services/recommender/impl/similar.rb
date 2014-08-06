module Recommender
  module Impl
    class Similar < Recommender::Weighted
      PRICE_UP = 1.25
      PRICE_DOWN = 0.85
      LIMIT = 20

      def check_params
        params.item.present?
      end

      def category_query
        if params.categories.present? && params.categories.any? 
          "AND (array[#{params.categories.map{|c| "'#{c}'" }.join(',')}]::VARCHAR[] <@ items.categories)"
        else
          "AND (array[#{params.item.categories.map{|c| "'#{c}'" }.join(',')}]::VARCHAR[] <@ items.categories)"
        end
      end

      def price_query
        if params.item.price.present?
          "AND (items.price BETWEEN #{PRICE_DOWN * params.item.price} AND #{PRICE_UP * params.item.price})"
        end
      end

      def items_in_category_query
        "
         SELECT items.id FROM items WHERE
         is_available = true AND
         shop_id = #{params.shop.id}
         #{price_query}
         #{category_query}
        "
      end

      def min_date
        1.month.ago.to_date.to_time.to_i
      end

      def items_to_weight
        Action.connection.execute("
          SELECT item_id FROM actions
          WHERE
            item_id IN (#{items_in_category_query})
            AND timestamp > #{min_date}
            #{locations_query}
            #{item_query}
          GROUP BY item_id
          ORDER BY avg(rating) desc
          LIMIT #{LIMIT}
        ").map{|i| i['item_id'].to_i }
      end
    end
  end
end
