module TriggerMailings
  module Events
    class AbandonedCart < Base
      def happened?
        @user.actions.where('rating::numeric = ?', Actions::Cart::RATING).where(shop: @shop).each do |a|
          @happened_at = a.cart_date
          @source_item = a.item
          return true
        end
      end
    end
  end
end
