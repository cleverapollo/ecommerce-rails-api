module Recommender
  module Impl
    class RecentlyViewed < Recommender::Raw
      LIMIT = 10

      def recommended_ids
        Action.connection.execute("
          SELECT item_id FROM actions
          WHERE
            shop_id = #{params.shop.id}
            AND user_id = #{params.user.id}
            AND view_count > 0
          ORDER BY view_date DESC
          LIMIT #{LIMIT}
        ").map{|i| i['item_id'].to_i }
      end
    end
  end
end
