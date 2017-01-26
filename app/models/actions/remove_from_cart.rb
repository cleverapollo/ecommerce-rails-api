##
# Удаление из корзины
#
module Actions
  class RemoveFromCart < Action
    CODE = 4
    RATING = 3.7

    def mass_process

      # Убираем из корзины удаленные товары
      if params.items.any?
        if cart = ClientCart.find_by(shop_id: params.shop.id, user_id: params.user.id)
          cart.remove_from_cart(params.items.map(&:id))
        end
      end
    end

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
