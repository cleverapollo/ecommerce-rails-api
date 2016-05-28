module TriggerMailings
  class SubscriptionForProduct

    class IncorrectMailingSettingsError < StandardError; end

    class << self

      # Подписать покупателя на снижение цены, чтобы в дальнейшем использовать
      # в триггере ProductPriceDecrease.
      # @param shop [Shop]
      # @param user [User]
      # @param item [Item]
      # @return SubscribeForProductPrice
      # @throws IncorrectMailingSettingsError
      #
      def subscribe_for_price(shop, user, item)

        raise IncorrectMailingSettingsError if shop.nil?
        raise IncorrectMailingSettingsError if user.nil?
        raise IncorrectMailingSettingsError if item.nil?

        if element = SubscribeForProductPrice.find_by(shop_id: shop.id, user_id: user.id, item_id: item.id)
          element.update subscribed_at: DateTime.current
        else
          element = SubscribeForProductPrice.create shop_id: shop.id, user_id: user.id, item_id: item.id, subscribed_at: DateTime.current
        end

        element
      end


      # Подписать покупателя на появление товара в наличии, чтобы в дальнейшем использовать
      # в триггере ProductAvailable.
      # Если товар сейчас в наличии, то пользователь не подписывается на этот триггер.
      # @param shop [Shop]
      # @param user [User]
      # @param item [Item]
      # @return SubscribeForProductPrice
      # @throws IncorrectMailingSettingsError
      #
      def subscribe_for_available(shop, user, item)

        raise IncorrectMailingSettingsError if shop.nil?
        raise IncorrectMailingSettingsError if user.nil?
        raise IncorrectMailingSettingsError if item.nil?

        if element = SubscribeForProductAvailable.find_by(shop_id: shop.id, user_id: user.id, item_id: item.id)
          element.update subscribed_at: DateTime.current
        else
          element = SubscribeForProductAvailable.create shop_id: shop.id, user_id: user.id, item_id: item.id, subscribed_at: DateTime.current
        end

        element
      end



      # Очищает просроченные подписки
      # @return nil
      def cleanup
        SubscribeForProductPrice.where('subscribed_at <= ?', 6.months.ago).delete_all
        SubscribeForProductAvailable.where('subscribed_at <= ?', 6.months.ago).delete_all
        nil
      end

    end

  end
end