module Actions
  class Purchase < Action
    CODE = 3
    RATING = 5

    def update_rating_and_last_action(rating)
      self.last_action = CODE
      self.rating = RATING
    end

    def update_concrete_action_attrs
      self.cart_count ||= 1
      self.cart_date ||= Date.current

      self.purchase_count += 1
      self.purchase_date = Date.current
    end

    def needs_to_update_rating?
      true
    end
  end
end
