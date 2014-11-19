module TriggerMailings
  class EventDetector
    class << self
      def process_all_subscriptions
        Subscription.active.includes(:user, :shop).find_each do |subscription|
          process(subscription.user, subscription.shop)
        end
      end

      def process(user, shop)
        events = []

        events_implementations.each do |implementation|
          i = implementation.new(user, shop)
          events << i if i.happened?
        end

        events
      end

      private

      def events_implementations
        [TriggerMailings::Events::AbandonedCart, TriggerMailings::Events::RecentlyPurchased, TriggerMailings::Events::SlippingAway, TriggerMailings::Events::ViewedButNotBought]
      end
    end
  end
end
