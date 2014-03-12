module Recommender
  module Impl
    class Interesting < Recommender::UserBased
      def recommended_ids
        if params.user.present? and params.user.actions.where(shop_id: params.shop.id).count > 4
          super
        end

        []
      end
    end
  end
end
