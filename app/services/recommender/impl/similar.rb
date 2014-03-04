module Recommender
  module Impl
    class Similar < Recommender::Filtered
      PRICE_UP = 1.25
      PRICE_DOWN = 0.85
      LIMIT = 20

      def category_query
        if params.category.present?
          "AND category_uniqid = '#{params.item.category_uniqid}'"
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
            AND (price BETWEEN #{PRICE_DOWN * params.item.price} AND #{PRICE_UP * params.item.price})
            AND timestamp > #{min_date}
            #{category_query}
          GROUP BY item_id
          ORDER BY avg(rating) desc
          LIMIT #{LIMIT}
        ").map{|i| i['item_id']}.to_i
      end
    end
  end
end
