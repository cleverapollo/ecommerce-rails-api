module Recommender
  module Impl
    ##
    # Ранжирующий рекомендер. Никогда никем не использовался.
    #
    class Rescore < Recommender::Weighted
      def check_params!
        raise Recommendations::IncorrectParams.new('Items required for this recommender') if params.items.blank? || params.items.none?
      end

      # Точка входа
       def recommendations
         result = super

         # Просто добавляем в конец отсутствующие товары в базе
         result + (params.items - result)
       end

      def items_to_weight
        items_to_recommend.where(uniqid: params.items).pluck(:id)
      end

      # Нельзя добавлять товары
      def inject_items(result)
        result
      end
    end
  end
end
