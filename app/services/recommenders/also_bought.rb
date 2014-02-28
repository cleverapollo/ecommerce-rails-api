module Recommenders
  class AlsoBought < Base
    LIMIT = 20

    def items_to_estimate
      Rails.cache.fetch([:also_bought, params.shop.id, params.user.id, params.item_id, params.cart_item_ids], expires_in: 20.minutes) do
        cart_query = if params.cart_item_ids.any?
          "AND item_id NOT IN (#{params.cart_item_ids.join(',')})"
        else
          ''
        end

        q = Action.connection.execute("
          SELECT actions.item_id FROM actions
          INNER JOIN items
            ON items.id = actions.item_id
            AND items.shop_id = #{params.shop.id}
            AND (items.is_available = true or items.is_available IS NULL)
          WHERE
            item_id NOT IN (
              SELECT item_id FROM actions
              WHERE
                purchase_count > 0
                AND user_id = #{params.user.id}
            )
            AND user_id IN (
              SELECT DISTINCT user_id FROM actions
              WHERE
                purchase_count > 0
                AND item_id = #{params.item_id}
            )
            #{cart_query}
            AND actions.shop_id = #{params.shop.id}
            AND purchase_count > 0
          GROUP BY actions.item_id
          HAVING sum(purchase_count) > 0
          ORDER BY sum(purchase_count) DESC
          LIMIT #{LIMIT}
        ")

        q = q.map{|i| i['item_id'].to_i }
      end
    end
  end
end
