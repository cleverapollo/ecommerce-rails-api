##
# Добавление в корзину
#
module Actions
  class Cart < Action
    CODE = 2
    RATING = 4.2

    class << self
      # Сохранение слепка корзины, если товаров больше одного (см. JS SDK v3)
      # Те товары, которые были в корзине, сделать "удален из корзины"
      # Текущие товары отметить как в корзине
      def mass_process(params)
        if params.items.count > 1
          params.user.actions.carts.where.not(item_id: params.items.map(&:id)).update_all rating: Actions::RemoveFromCart::RATING, cart_count: 0
          params.user.actions.carts.where(item_id: params.items.map(&:id)).each do |action|
            action.update rating: Actions::Cart::RATING, cart_count: params.items.select { |x| x.id == action.item_id }.first.amount
          end
        elsif params.items.count == 0
          # Если пустой массив, значит корзину очистили
          params.user.actions.carts.each do |action|
            action.update rating: Actions::RemoveFromCart::RATING, cart_count: 0
          end
        end
      end
    end

    def update_rating_and_last_action(rating)
      self.last_action = CODE
      self.rating = RATING
    end

    def update_concrete_action_attrs
      self.cart_count += 1
      self.cart_date = Time.current
    end

    def needs_to_update_rating?
      (self.last_action == Actions::View::CODE) ||
      (self.last_action == Actions::RemoveFromCart::CODE)
    end
  end
end
