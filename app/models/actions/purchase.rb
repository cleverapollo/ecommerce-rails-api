##
# Покупка
#
module Actions
  class Purchase < Action
    CODE = 3
    RATING = 5

    class << self
      # Сохранение объекта заказа
      def mass_process(params)
        Order.persist(params.shop, params.user, params.order_id, params.items, params.source, params.order_price)
      end
    end

    def update_rating_and_last_action(rating)
      self.last_action = CODE
      self.rating = RATING
    end

    def update_concrete_action_attrs
    end

    # @param [ActionPush::Params] params
    def post_process(params)
      params.client.bought_something = true
      params.client.supply_trigger_sent = nil
      params.client.save if params.client.changed?
      params.user.client_carts.destroy_all
    end

    def needs_to_update_rating?
      true
    end
  end
end
