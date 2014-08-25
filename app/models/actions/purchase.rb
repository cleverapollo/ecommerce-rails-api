module Actions
  class Purchase < Action
    CODE = 3
    RATING = 5

    class << self
      def mass_process(params)
        Order.persist(params.shop, params.user, params.order_id, params.items)
      end
    end

    def update_rating_and_last_action(rating)
      self.last_action = CODE
      self.rating = RATING
    end

    def update_concrete_action_attrs
      self.cart_count ||= 1
      self.cart_date ||= Time.current

      self.purchase_count += 1
      self.purchase_date = Time.current
    end

    def post_process
      ShopsUser.where(user_id: self.user_id, shop_id: self.shop_id).update_all(bought_something: true)
    end

    def needs_to_update_rating?
      true
    end
  end
end
