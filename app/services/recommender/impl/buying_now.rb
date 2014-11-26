module Recommender
  module Impl
    class BuyingNow < Recommender::Weighted
      LIMIT = 20

      def items_to_weight
        min_date = 1.day.ago.to_i

        # Выводит топ товаров за последние сутки.
        # Те, что чаще покупаются - будут выше.
        # Если покупок нет, все равно будет работать.
        result = shop.actions.available.where('timestamp >= ?', min_date)
        result = result.where.not(item_id: excluded_items_ids)
        result = result.in_locations(locations)
        result = result.group(:item_id)
        result = result.order('SUM(purchase_count) DESC, SUM(view_count) DESC')
        result = result.limit(LIMIT).pluck(:item_id)
        unless shop.strict_recommendations?
          result = inject_random_items(result)
        end
        result
      end
    end
  end
end
