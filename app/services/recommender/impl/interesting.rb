module Recommender
  module Impl
    class Interesting < Recommender::UserBased
      def recommended_ids
        if params.user.present? and params.user.actions.select(:id).where(shop_id: params.shop.id).limit(4).size == 4
          super
        end

        []
      end
    end
  end
end
