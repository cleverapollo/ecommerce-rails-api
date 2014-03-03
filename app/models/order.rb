class Order < ActiveRecord::Base
  belongs_to :shop
  belongs_to :user

  class << self
    def persist(shop, user, uniqid, items)
      return if duplicate?(shop, user, uniqid, items)

      uniqid = generate_uniqid if uniqid.blank?

      order = Order.create(shop_id: shop.id, user_id: user.id, uniqid: uniqid)

      items.each do |item|
        OrderItem.persist(order, item, item.amount)
      end
    end

    def duplicate?(shop, user, uniqid, items)
      if uniqid.present?
        Order.where(uniqid: uniqid, shop_id: shop.id).any?
      else
        Order.where(shop_id: shop.id, user_id: user.id)
             .where("date > (localtimestamp - interval '5 minute')").any?
      end
    end

    def generate_uniqid
      loop do
        uuid = SecureRandom.uuid
        return uuid if Order.where(uniqid: uuid).none?
      end
    end
  end
end
