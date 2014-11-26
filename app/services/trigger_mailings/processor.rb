module TriggerMailings
  class Processor
    class << self
      def process_all
        events = []
        scoped_subscriptions.find_each do |subscription|
          if event = TriggerMailings::EventDetector.detect(subscription.user, subscription.shop)
            events << event
          end
        end

        events.each{|e| puts e }
      end

      def scoped_subscriptions
        Subscription.active.includes(:shop, :user)
      end
    end
  end
end
