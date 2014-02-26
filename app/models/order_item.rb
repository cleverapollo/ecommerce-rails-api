class OrderItem < ActiveRecord::Base
  belongs_to :order
  belongs_to :item
  belongs_to :action

  class << self
    def persist(order, item, amount)
      action = Action.find_by(item_id: item.id, user_id: order.user.id) || Action.new
      OrderItem.create!(order_id: order.id,
                        item_id: item.id,
                        action_id: action.id,
                        amount: amount,
                        recommended_by: action.recommended_by)
    end
  end
end
