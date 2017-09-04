##
# Товар в заказе
#
class OrderItem < ActiveRecord::Base

  belongs_to :order
  belongs_to :item
  belongs_to :action
  belongs_to :shop

  validates :shop_id, :action_id, presence: true

  class << self
    # Сохранить товар заказа
    def persist(order, item, amount, recommended_by = nil)

      action = Action.find_by(item_id: item.id, user_id: order.user_id)
      if action.nil?
        begin
          action = Action.atomic_create!(item_id: item.id, user_id: order.user_id, shop_id: order.shop_id, rating: Actions::Purchase::RATING, recommended_by: recommended_by, recommended_at: recommended_by.present? ? Time.current : nil)
        rescue
          action = Action.find_by(item_id: item.id, user_id: order.user_id)
        end
      end

      # todo @deprecated, удалить Action, брать из Clickhouse
      # Если recommended_by не указан, но в Action был recommended_by и он не устарел, то используем его
      # Для триггеров и дайджестов это 2 дня, для всех остальных 2 недели
      if recommended_by.nil? && action.recommended_by && action.recommended_at.present?
        if %w(trigger_mail digest_mail).include?(action.recommended_by)
          recommended_by = action.recommended_by if action.recommended_at <= 2.day.ago
        elsif action.recommended_at >= Order::RECOMMENDED_BY_DECAY.ago
          recommended_by = action.recommended_by
        end
      end

      result = OrderItem.atomic_create!(order_id: order.id,
                                 item_id: item.id,
                                 action_id: action.id,
                                 shop_id: order.shop_id,
                                 amount: amount,
                                 recommended_by: recommended_by)

      action.recalculate_purchase_count_and_date! if action.persisted?

      # Если товар входит в список продвижения
      Promoting::Brand.find_by_item(item, false).each do |brand_campaign_id|

        # В ежедневную статистику
        BrandLogger.track_purchase brand_campaign_id, order.shop_id, recommended_by

        # В продажи бренда
        BrandCampaignPurchase.create! order_id: order.id, item_id: item.id, shop_id: order.shop_id, brand_campaign_id: brand_campaign_id, date: Date.current, price: (item.price || 0), recommended_by: recommended_by
      end

      result
    end
  end
end
