module Recommender
  module Impl
    class Experiment < Recommender::Impl::Popular
      def items_to_recommend
        if params.modification.present?
          result = super
          if params.modification == 'fashion'
            if categories.try(:any?)
              # в категории
            else
              # на главной
              gender_algo = SectoralAlgorythms::Wear::Gender.new(params.user)
              result = gender_algo.modify_relation(result)
            end
          end
          result
        else
          super
        end
      end
    end
  end
end
