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
          item: source_item,
          limit: count,
          recommend_only_widgetable: true,
          locations: source_item.locations
        )

        # Сначала похожие товары
        result = Recommender::Impl::Similar.new(params).recommended_ids

        # Затем интересные
        if result.count < count
          result += Recommender::Impl::Interesting.new(params.tap { |p|
            p.limit = (count - result.count)
            p.exclude = result
          }).recommended_ids
        end

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
