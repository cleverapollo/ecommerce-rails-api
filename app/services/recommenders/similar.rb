module Recommenders
  class Similar < Base
    PRICE_UP = 1.25
    PRICE_DOWN = 0.85
    LIMIT = 20
    INTERVAL = '2 month'

    def items_to_estimate
      Rails.cache.fetch(cache_key, expires_in: 30.seconds) do
        item = Item.find(params.item_id)

        category_query = if item.category_uniqid.present?
          "AND items.category_uniqid = '#{item.category_uniqid}'"
        else
          ""
        end

        q = Action.connection.execute("
          SELECT actions.item_id FROM actions
          INNER JOIN items
            ON items.id = actions.item_id
            AND items.shop_id = #{params.shop.id}
            AND (items.is_available = true or items.is_available IS NULL)
            AND (items.price between #{PRICE_DOWN * item.price} AND #{PRICE_UP * item.price})
            #{category_query}
          WHERE
            actions.item_id != #{params.item_id} AND
            actions.timestamp > extract(epoch from now() - interval '#{INTERVAL}')
          GROUP BY actions.item_id
          ORDER BY avg(rating) desc
          LIMIT #{LIMIT}
        ")

        q = q.map{|i| i['item_id'].to_i }
      end
    end

    def cache_key
      [:similar, params.shop.id, params.item_id, params.cart_item_ids]
    end
  end
end
