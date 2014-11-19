module TriggerMailings
  class EventDetector
    class << self
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
        [TriggerMailings::Events::AbandonedCart]
      end
    end
  end
end
