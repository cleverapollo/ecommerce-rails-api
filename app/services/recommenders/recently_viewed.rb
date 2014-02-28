module Recommenders
  class RecentlyViewed < Base
    LIMIT = 10

    def raw_recommendations
      q = Action.connection.execute("
        SELECT item_id FROM actions
        INNER JOIN items
          ON items.id = actions.item_id
          AND items.shop_id = #{params.shop.id}
        WHERE
          view_count > 0
          AND user_id = #{params.user.id}
        ORDER BY view_date desc
        LIMIT #{params[:limit] || LIMIT}
      ")

      q = q.map{|i| i['item_id'].to_i }
    end
  end
end
