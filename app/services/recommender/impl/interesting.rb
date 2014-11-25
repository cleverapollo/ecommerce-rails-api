module Recommender
  module Impl
    class Interesting < Recommender::UserBased
      def recommended_ids
        result = super
        unless shop.strict_recommendations?
          result = inject_not_bought_but_carted_id_in(result)
          result = inject_random_items(result)
        end
        result
      end

      def inject_not_bought_but_carted_id_in(ids)
        relation = user.actions.where(shop_id: shop.id)
        relation = relation.where("rating = '#{Actions::Cart::RATING}'::real")
        relation = relation.where('cart_date <= ?', 30.minutes.ago)
        relation = relation.where('cart_date >= ?', 24.hours.ago)
        id = relation.limit(1).pluck(:item_id).first

        if id.present? && id != item.try(:id) && !ids.include?(id)
          ids.insert(2, id).first(limit)
        else
          ids
        end
      end
    end
  end
end
