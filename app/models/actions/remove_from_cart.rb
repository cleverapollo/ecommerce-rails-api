##
# Удаление из корзины
#
module Actions
  class RemoveFromCart < Action
    CODE = 4
    RATING = 3.7

    def update_rating_and_last_action(rating)
      self.last_action = CODE
      self.rating = RATING
    end

    def update_concrete_action_attrs
      # Убираем товар из корзины
      self.cart_count = 0
    end

    def needs_to_update_rating?
      (self.last_action == Actions::Cart::CODE) ||
      (self.last_action == Actions::View::CODE)
    end
  end
end
