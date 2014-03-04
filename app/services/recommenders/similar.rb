module Recommenders
  class Similar < Base
    PRICE_UP = 1.25
    PRICE_DOWN = 0.85
    LIMIT = 20
    INTERVAL = '2 month'

    def category_query
      if params.category.present?
        "AND category_uniqid = '#{params.item.category_uniqid}'"
      end
    end

    def min_date
      1.month.ago.to_date.to_time.to_i
    end

    def similar_item_ids
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

    def cache_key
      [:similar, params.shop.id, params.item_id, params.cart_item_ids]
    end

    def items_to_estimate
      Rails.cache.fetch(cache_key, expires_in: 30.seconds) do
        similar_item_ids
      end
    end
  end
end
