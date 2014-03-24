module Recommender
  module Impl
    class Interesting < Recommender::UserBased
      def recommended_ids
        if params.user.present? and params.user.actions.select(:id).where(shop_id: params.shop.id).limit(4).size == 4
          res = super
          if params.item.present?
            res = res - [params.item.id]
          end
          return res
        end

        []
      end
    end
  end
end
