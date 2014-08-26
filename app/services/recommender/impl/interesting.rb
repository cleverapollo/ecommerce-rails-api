module Recommender
  module Impl
    class Interesting < Recommender::UserBased
      def recommended_ids
        res = super
        if params.item.present?
          res = res - [params.item.id]
        end

        id = not_bought_but_carted_id
        if id.present? && id != params.item.try(:id)
          res = res.insert(2, id)
          res.compact!
        end

        res
      end

      def not_bought_but_carted_id 
        relation = params.user.actions.where(shop_id: params.shop.id)
        relation = relation.where("rating = '#{Actions::Cart::RATING}'::real")
        relation = relation.where('cart_date <= ?', 30.minutes.ago)
        relation = relation.where('cart_date >= ?', 24.hours.ago)
        relation.limit(1).pluck(:item_id).first
      end
    end
  end
end
