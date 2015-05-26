module Recommender
  module Impl
    class Experiment < Recommender::Personalized

      K_SR = 1.0
      K_CF = 10000.0

      def items_to_weight
        result = items_to_recommend.where.not(id: excluded_items_ids).limit(LIMIT_CF_ITEMS)

        # Преобразуем result к виду {id=>weight}
        result.to_a.map{|value| [value.id,value.sales_rate]}.to_h
      end


      # @return Int[]
      def rescore(items_weighted, cf_weighted)
        items_weighted.merge(cf_weighted) do |key, sr, cf|
          # подмешиваем оценку SR
          (K_SR*sr.to_f + K_CF*cf.to_f)/(K_CF+K_SR)
        end
      end


      def inject_promotions(result)
        # Не надо включать промо
        result
      end

      def inject_random_items(result)
        # Не включать рандомные итемы
        result
      end
    end
  end
end
