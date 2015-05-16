class SalesRateCalculator
  class << self
    def perform
      Shop.unrestricted.each do |shop|
        item_ids = shop.actions.where('timestamp > ?', 3.month.ago.to_date.to_time.to_i)
      end
      # Action.carts.where('cart_date < ?', 2.days.ago).find_each do |action|
      #   action.update(rating: Actions::RemoveFromCart::RATING, last_action: Actions::Cart::CODE)
      # end
    end
  end
end