module Recommenders
  class Popular < Base
    LIMIT = 20

    def category_query
      if params.category_uniqid.present?
        "AND category_uniqid = '#{params.category_uniqid}'"
      end
    end

    def min_date
      1.month.ago.to_date.to_time.to_i
    end

    def popular_item_ids
      Action.connection.execute("
        SELECT item_id
        FROM actions
        WHERE
          timestamp > #{min_date}
          AND shop_id = #{params.shop.id}
          #{category_query}
          AND is_available = true
        GROUP BY item_id
        HAVING SUM(purchase_count) > 0
        ORDER BY AVG(rating) DESC
        LIMIT #{LIMIT}
      ").map{|i| i['item_id'].to_i }
    end

    def items_to_estimate
#Rails.cache.fetch([:popular, params.shop.id, params.category_uniqid], expires_in: 20.minutes) do
        popular_item_ids
      #end
    end
  end
end
