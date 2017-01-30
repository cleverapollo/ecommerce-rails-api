module TriggerMailings
  module Triggers
    ##
    # Триггер "Потвержение e-mail".
    #
    class DoubleOptIn < Base

      def condition_happened?
        false
      end

      def recommended_ids(count)
        params = OpenStruct.new(
          shop: shop,
          user: user,
          limit: count,
          recommend_only_widgetable: true,
        )

        # Сначала интересные товары
        result = Recommender::Impl::Interesting.new(params).recommended_ids

        # Потом популярные
        if result.count < count
          result += Recommender::Impl::Popular.new(params.tap { |p|
            p.limit = (count - result.count)
            p.exclude = result
          }).recommended_ids
        end

        result
      end

      def priority
        -100
      end
    end
  end
end
