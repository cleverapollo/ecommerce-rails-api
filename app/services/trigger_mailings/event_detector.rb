module TriggerMailings
  class EventDetector
    class << self
      def detect(user, shop)
        events = events_implementations.map do |implementation|
          i = implementation.new(user, shop)
          i if i.happened?
        end.compact.sort{|x, y| x.rating <=> y.rating }.first
      end

      private

      def events_implementations
        [TriggerMailings::Events::AbandonedCart,
         TriggerMailings::Events::RecentlyPurchased,
         TriggerMailings::Events::SlippingAway,
         TriggerMailings::Events::ViewedButNotBought]
      end
    end
  end
end
