module TriggerMailings
  class SubscriptionForCategory

    class IncorrectMailingSettingsError < StandardError; end

    class << self

      # Подписать покупателя на событие просмотра категории, чтобы в дальнейшем использовать
      # в триггере AbandonedCategory.
      # @param shop [Shop]
      # @param user [User]
      # @param category [ItemCategory]
      # @return SubscribeForCategory
      # @throws IncorrectMailingSettingsError
      #
      def subscribe(shop, user, category)

        raise IncorrectMailingSettingsError.new('Shop not set for abandoned category trigger') if shop.nil?
        raise IncorrectMailingSettingsError.new('User not found for abandoned category trigger') if user.nil?
        raise IncorrectMailingSettingsError.new('Incorrect category for abandoned category trigger') if category.nil?

        if element = SubscribeForCategory.find_by(shop_id: shop.id, user_id: user.id, item_category_id: category.id)
          element.update subscribed_at: DateTime.current
        else
          begin
            element = SubscribeForCategory.create shop_id: shop.id, user_id: user.id, item_category_id: category.id, subscribed_at: DateTime.current
          rescue => e
            # Concurrency
          end
        end

        element
      end



      # Очищает просроченные подписки на просмотренные категории
      # @return SubscribeForCategory[]
      def cleanup
        SubscribeForCategory.where('subscribed_at <= ?', 48.hours.ago).delete_all
      end

    end

  end
end