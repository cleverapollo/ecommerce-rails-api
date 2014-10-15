module Recommender
  module Impl
    class Rescore < Recommender::Weighted
      def check_params!
        raise Recommendations::IncorrectParams.new('Items required for this recommender') if params.items.blank? || params.items.none?
      end

      def items_to_weight
        params.shop.items.where(uniqid: params.items).pluck(:id)
      end
    end
  end
end
