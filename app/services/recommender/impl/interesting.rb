module Recommender
  module Impl
    class Interesting < Recommender::UserBased
      def recommended_ids
        if params.user.present?
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
