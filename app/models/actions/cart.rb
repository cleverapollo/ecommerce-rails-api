module Actions
  class Cart < Action
    CODE = 2
    RATING = 4.2

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
