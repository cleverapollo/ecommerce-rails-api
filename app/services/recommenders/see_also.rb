module Recommenders
  class SeeAlso < Base
    LIMIT = 20

    def items_to_estimate
      Rails.cache.fetch([:see_also, params.shop.id, params.user.id, params.cart_item_ids], expires_in: 30.seconds) do
        q = Action.connection.execute("
                                        select actions.item_id
                                        from actions
                                        inner join items on actions.item_id = items.id and
                                        items.is_available != false
                                        where
                                        item_id not in (select item_id from actions where purchase_count > 0 and user_id = #{params.user.id}) and
                                        user_id in (select distinct user_id from actions where purchase_count > 0 and
                                        item_id IN (#{params.cart_item_ids.join(',')})) and
                                        actions.shop_id = #{params.shop.id} and
                                        purchase_count > 0 and
                                        item_id not in (#{params.cart_item_ids.join(',')})
                                        group by actions.item_id
                                        having sum(purchase_count) > 0
                                        order by sum(purchase_count) desc
                                        limit #{LIMIT}")
        q = q.map{|i| i['item_id'].to_i }
      end
    end
  end
end
