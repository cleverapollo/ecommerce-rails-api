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
        if params.item.category_uniqid.present?
          "AND category_uniqid = '#{params.item.category_uniqid}'"
        end
      end

      def price_query
        if params.item.price.present?
          "AND (price BETWEEN #{PRICE_DOWN * params.item.price} AND #{PRICE_UP * params.item.price})"
        end
      end

      def min_date
        1.month.ago.to_date.to_time.to_i
      end

      def items_to_weight
        Action.connection.execute("
          SELECT item_id FROM actions
          WHERE
            shop_id = #{params.shop.id}
            AND is_available = true
            #{price_query}
            AND timestamp > #{min_date}
            #{category_query}
            #{item_query}
          GROUP BY item_id
          ORDER BY avg(rating) desc
          LIMIT #{LIMIT}
        ").map{|i| i['item_id'].to_i }
      end
    end
  end
end
