module TriggerMailings
  module Triggers
    class SlippingAway < Base
      def condition_happened?
        # Юзер не заходил на сайт три месяца
        if user.actions.where(shop: shop).any? && user.actions.where(shop: shop).where('view_date >= ?', 3.month.ago).none?
          return true
        else
          return false
        end
      end

      # Рекомендации для неактивнго пользователя
      def recommended_ids(count)
        # В первую очередь то, что его может заинтересовать
        result = Recommender::Impl::Interesting.new(OpenStruct.new(
          shop: shop,
          user: user,
          limit: count,
          recommend_only_widgetable: true
        )).recommended_ids

        # Затем то, что он недавно смотрел
        if result.count < count
          result += Recommender::Impl::RecentlyViewed.new(OpenStruct.new(
            shop: shop,
            user: user,
            limit: count,
            exclude: result,
            recommend_only_widgetable: true
          )).recommended_ids
        end

        # Наконец, популярные товары
        if result.count < count
          result += Recommender::Impl::Popular.new(OpenStruct.new(
            shop: shop,
            user: user,
            limit: count,
            exclude: result,
            recommend_only_widgetable: true
          )).recommended_ids
        end

        result
      end

      def priority
        1
      end
    end
  end
end
