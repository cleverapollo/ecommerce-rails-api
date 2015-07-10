##
# Товар в заказе
#
class OrderItem < ActiveRecord::Base

  belongs_to :order
  belongs_to :item
  belongs_to :action

  class << self
    # Сохранить товар заказа
    def persist(order, item, amount, recommended_by = nil)
      action = Action.find_by(item_id: item.id, user_id: order.user.id) || Action.new
      recommended_by ||= action.recommended_by

      result = OrderItem.create!(order_id: order.id,
                                 item_id: item.id,
                                 action_id: action.id,
                                 amount: amount,
                                 recommended_by: recommended_by)

      action.recalculate_purchase_count_and_date! if action.persisted?

      # Если товар входит в список продвижения
      Promoting::Brand.find_by_item(item).each do |advertiser_id|

        # В ежедневную статистику
        BrandLogger.track_purchase advertiser_id, order.shop_id, recommended_by

        # В продажи бренда
        AdvertiserPurchase.create order_id: order.id, item_id: item.id, shop_id: order.shop_id, advertiser_id: advertiser_id, date: Date.current, price: (item.price || 0), recommended_by: recommended_by
      end

      result
    end
  end
end
