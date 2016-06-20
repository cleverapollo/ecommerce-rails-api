module Recommender
  module Impl
    ##
    # Ранжирующий рекомендер. Никогда никем не использовался.
    #
    class Rescore < Recommender::Weighted
      def check_params!
        raise Recommendations::IncorrectParams.new('Items required for this recommender') if params.items.blank? || params.items.none?
      end

      def items_to_weight
        items_to_recommend.where(uniqid: params.items).pluck(:id)
      end
    end
  end
end
