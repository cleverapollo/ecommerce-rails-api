module Recommender
  module Impl
    class Experiment < Recommender::Impl::Interesting
      def recommended_ids

        excluded_items = excluded_items_ids

        ms = MahoutService.new(shop.brb_address)
        ms.open

        result = []
        opposite_gender = SectoralAlgorythms::Wear::Gender.new(params.user).opposite_gender
        while result.size<params.limit
          result = fetch_user_based(excluded_items, ms)
          break if result.empty?
          # уберем товары, которые не актуальные или не соответствуют полу
          result = Item.where(id: result).pluck(:id, :widgetable, :gender).delete_if { |val| !val[1] || val[2]==opposite_gender }.map{|v| v[0]}
          excluded_items = (excluded_items+result).compact.uniq
        end

        ms.close

        if result.size > params.limit
          result.take(params.limit)
        else
          result
        end
      end
    end
  end
end
