module Recommender
  module Impl
    class Rescore < Recommender::Weighted
      def check_params
        params.limit = 1000
        params.items.present? && params.items.any?
      end

      def items_to_weight
        params.shop.items.where(uniqid: params.items).pluck(:id)
      end
    end
  end
end
