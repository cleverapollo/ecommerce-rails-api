module Recommenders
  class Popular < Base
    LIMIT = 20
    INTERVAL = '1 month'

    def items_to_estimate
      Rails.cache.fetch([:popular, params.shop.id, params.category_uniqid], expires_in: 20.minutes) do
        category_query = if params.category_uniqid.present?
          "and items.category_uniqid = '#{params.category_uniqid}'"
        else
          ""
        end

        q = Action.connection.execute("
                                        select actions.item_id
                                        from actions
                                        left join items on actions.item_id = items.id
                                        where actions.timestamp > extract(epoch from now() - interval '#{INTERVAL}')
                                        and items.is_available != false
                                        and actions.shop_id = #{params.shop.id}
                                        #{category_query}
                                        group by actions.item_id
                                        having sum(purchase_count) > 0
                                        order by avg(rating) desc
                                        limit #{LIMIT}")
        q = q.map{|i| i['item_id'].to_i }
      end
    end
  end
end
