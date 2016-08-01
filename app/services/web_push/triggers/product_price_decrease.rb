module WebPush
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

      # Срабатывает в случае, если цена на товар снизилась больше, чем на 1%.
      # При этом товар не был куплен.
      # Удаляет подписки из БД
      def condition_happened?
        subscriptions = user.subscribe_for_product_prices.where(shop: shop).where(subscribed_at: trigger_time_range)
        if subscriptions.any?
          # Находим подходящие товары и сразу устанавливаем oldprice в цену, по которой клиент подписывался
          @items = subscriptions.map { |subscription|
            (subscription.item.oldprice = subscription.price; subscription.item) if subscription.item.present? && subscription.item.is_available? &&
                subscription.item.price_at_location(client.location) <= subscription.price * 0.99 &&
                !OrderItem.where(item_id: subscription.item_id, order_id: Order.where(shop_id: shop.id, user_id: user.id).select(:id) ).exists?
          }.uniq.compact
          if @items.any?
            @happened_at = Time.current
            user.subscribe_for_product_prices.where(shop: shop, item_id: @items.map(&:id) ).destroy_all
            return true
          end
        end
        false
      end


    end
  end
end
