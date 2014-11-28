module TriggerMailings
  ##
  # Класс, отвечающий за обработку подписок
  #
  class SubscriptionsProcessor
    class << self
      # Обработать все подписки: искать для каждой триггеры, если есть - отправить письмо.
      def process_all
        scoped_subscriptions.find_each do |subscription|
          if trigger = TriggerMailings::TriggerDetector.detect(subscription.user, subscription.shop)
            TriggerMailings::Letter.new(subscription, trigger).send
            subscription.set_dont_disturb! unless Rails.env.development?
          end
        end
      end

      private

      # Релейшн с подписками, подходящими для обработки
      #
      # @return [ActiveRecord::Relation] подписки
      # @private
      def scoped_subscriptions
        Subscription.active.where('dont_disturb_until < ? OR dont_disturb_until IS NULL', Time.current).includes(:shop, :user)
      end
    end
  end
end
