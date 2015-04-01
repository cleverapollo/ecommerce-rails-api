class Order < ActiveRecord::Base
  RECOMMENDED_BY_DELAY = 2.weeks

  include UserLinkable

  has_many :order_items, dependent: :destroy
  belongs_to :source, polymorphic: true
  belongs_to :shop

  class << self
    def persist(shop, user, uniqid, items, source = {})
      return if duplicate?(shop, user, uniqid, items)

      uniqid = generate_uniqid if uniqid.blank?

      if source.present? && source['from'].present?
        klass = if source['from'] == 'trigger_mail'
          TriggerMail
        elsif source['from'] == 'digest_mail'
          DigestMail
        end

        source = klass.find_by(code: source['code'])
      else
        source = nil
      end

      values = order_values(shop, user, items, source.present?)

      order = Order.create! \
                           shop_id: shop.id,
                           user_id: user.id,
                           uniqid: uniqid,
                           common_value: values[:common_value],
                           recommended_value: values[:recommended_value],
                           value: values[:value],
                           recommended: (values[:recommended_value] > 0),
                           ab_testing_group: Client.where(user_id: user.id, shop_id: shop.id).first.try(:ab_testing_group),
                           source: source

      items.each do |item|
        recommended_by_expicit = source.present? ? source.class.to_s.underscore : nil
        OrderItem.persist(order, item, item.amount, recommended_by_expicit)
      end
    end

    def order_values(shop, user, items, force_recommended = false)
      result = { value: 0.0, common_value: 0.0, recommended_value: 0.0 }

      items.each do |item|
        if force_recommended || shop.actions.where(item_id: item.id, user_id: user.id).where('recommended_by is not null').where('recommended_at >= ?', RECOMMENDED_BY_DELAY.from_now).exists?
          result[:recommended_value] += (item.price.try(:to_f) || 0.0) * (item.amount.try(:to_f) || 1.0)
        else
          result[:common_value] += (item.price.try(:to_f) || 0.0) * (item.amount.try(:to_f) || 1.0)
        end
      end

      result[:value] = result[:common_value] + result[:recommended_value]

      result
    end

    def duplicate?(shop, user, uniqid, items)
      if uniqid.present?
        Order.where(uniqid: uniqid, shop_id: shop.id).any?
      else
        Order.where(shop_id: shop.id, user_id: user.id)
             .where("date > ?", 5.minutes.ago).any?
      end
    end

    def generate_uniqid
      loop do
        uuid = SecureRandom.uuid
        return uuid if Order.where(uniqid: uuid).none?
      end
    end
  end

  # Удаляет все товары из корзины для текущего пользователя и магазина
  def expire_carts
    user.actions.where(shop: shop).where('rating::numeric = ?', Actions::Cart::RATING).update_all(rating: Actions::RemoveFromCart::RATING)
  end
end
