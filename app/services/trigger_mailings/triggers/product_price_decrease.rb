module TriggerMailings
  module Triggers
    ##
    # Триггер "Цена на товар снижена"
    #
    class ProductPriceDecrease < Base
      # Отправляем, если подписка случилась в течение полугода
      def trigger_time_range
        (6.months.ago..240.minutes.ago)
      end

      def priority
        20
      end

      def appropriate_time_to_send?
        true
      end

      # Срабатывает в случае, если цена на товар снизилась больше, чем на 1%.
      # При этом товар не был куплен.
      # Удаляет подписки из БД
      def condition_happened?
        subscriptions = user.subscribe_for_product_prices.where(shop: shop).where(subscribed_at: trigger_time_range)
        if subscriptions.any?
          # Находим подходящие товары и сразу устанавливаем oldprice в цену, по которой клиент подписывался
          @source_items = subscriptions.map { |subscription|
            (subscription.item.oldprice = subscription.price; subscription.item) if subscription.item.present? && subscription.item.is_available? &&
                subscription.item.price_at_location(client.location) <= subscription.price * 0.99 &&
                !OrderItem.where(item_id: subscription.item_id, order_id: Order.where(shop_id: shop.id, user_id: user.id).select(:id) ).exists?
          }.uniq.compact
          if @source_items.any?
            @happened_at = Time.current
            @source_item = @source_items.first
            user.subscribe_for_product_prices.where(shop: shop, item_id: @source_items.map(&:id) ).destroy_all
            return true
          end
        end
        false
      end

      # Рекомендации берем похожие на каждый триггерный товар
      def recommended_ids(count)

        result = []

        @source_items.each do |item|

          params = OpenStruct.new(
              shop: shop,
              user: user,
              item: item,
              limit: count,
              recommend_only_widgetable: true,
              locations: client.location.present? ? [client.location] : nil
          )

          if result.count < count
            result += Recommender::Impl::Similar.new(params.tap { |p|
              p.limit = (count - result.count)
              p.exclude = result
            }).recommended_ids
          end

        end

        result

      end
    end
  end
end
