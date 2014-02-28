module Recommenders
  class AlsoBought < Base
    LIMIT = 20

    def items_to_estimate
      Rails.cache.fetch([:also_bought, params.shop.id, params.user.id, params.item_id, params.cart_item_ids], expires_in: 20.minutes) do
        cart_query = if params.cart_item_ids.any?
          "item_id not in (#{params.cart_item_ids.join(',')}) and"
        else
          ''
        end

        q = Action.connection.execute("
                                        select actions.item_id
                                        from actions
                                        inner join items on actions.item_id = items.id
                                        where
                                        item_id not in (select item_id from actions where purchase_count > 0 and user_id = #{params.user.id}) and
                                        user_id in (select distinct user_id from actions where purchase_count > 0 and item_id = #{params.item_id}) and
                                        #{cart_query}
                                        actions.shop_id = #{params.shop.id} and
                                        purchase_count > 0
                                        group by actions.item_id
                                        having sum(purchase_count) > 0
                                        order by sum(purchase_count) desc
                                        limit #{LIMIT}")
        q = q.map{|i| i['item_id'].to_i }
      end
    end
  end
end
