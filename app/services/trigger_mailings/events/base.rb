module TriggerMailings
  module Events
    class Base
      attr_accessor :shop, :user, :happened_at, :source_item, :additional_info

      def initialize(user, shop)
        @user = user
        @shop = shop
      end

      def happened?
        true
      end

      def to_s
        "#{self.class} by #{user} at #{happened_at} with #{source_item} #{additional_info}"
      end
    end
  end
end
