module Recommender
  module Impl
    class Experiment < Recommender::Impl::Interesting
      def items_to_recommend
        if params.modification.present?
          result = super
          if params.modification == 'fashion'
            gender_algo = SectoralAlgorythms::Wear::Gender.new(params.user)
            result = gender_algo.modify_relation(result)
          end
          result
        else
          super
        end
      end
    end
  end
end
