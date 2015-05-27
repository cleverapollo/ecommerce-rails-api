module Recommender
  module Impl
    class Experiment < Recommender::Impl::Popular


      # @return Int[]
      def rescore(items_weighted, cf_weighted)
        puts cf_weighted.inspect
        items_weighted.merge(cf_weighted) do |key, sr, cf|
          # подмешиваем оценку SR
          (K_SR*sr.to_f + K_CF*cf.to_f)/(K_CF+K_SR)
        end
      end


    end
  end
end
