module Recommender
  module Impl
    class BuyingNow < Recommender::Weighted
      LIMIT = 20

      def items_to_weight
        min_date = 1.day.ago.to_i

        result = shop.actions.available.where('timestamp >= ?', min_date)
        result = result.where.not(item_id: excluded_items_ids)
        result = result.in_locations(locations)
        result.group(:item_id).order('AVG(rating) DESC').limit(LIMIT).pluck(:item_id)
      end
    end
  end
end
