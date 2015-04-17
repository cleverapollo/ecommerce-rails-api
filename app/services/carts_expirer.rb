# Убираем товары из корзины, лежащие в корзине больше двух дней – освобождаем "интерес"
class CartsExpirer
  class << self
    def perform
      Action.carts.where('cart_date < ?', 2.days.ago).find_each do |action|
        action.update(rating: Actions::RemoveFromCart::RATING, last_action: Actions::Cart::CODE)
      end
    end
  end
end
