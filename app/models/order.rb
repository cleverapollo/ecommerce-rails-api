class Order < ActiveRecord::Base
  has_many :order_items, dependent: :destroy
  belongs_to :shop
  belongs_to :user

  class << self
    def persist(shop, user, uniqid, items)
      return if duplicate?(shop, user, uniqid, items)

      uniqid = generate_uniqid if uniqid.blank?

      begin
        order = Order.create \
                             shop_id: shop.id,
                             user_id: user.id,
                             uniqid: uniqid,
                             value: items.map{|i| (i.price.try(:to_f) || 0.0) * (i.amount.try(:to_f) || 1.0) }.sum,
                             recommended: Action.where(id: items.map(&:id)).where('recommended_by is not null').any?,
                             ab_testing_group: ShopsUser.where(user_id: user.id, shop_id: shop.id).first.try(:ab_testing_group)

        items.each do |item|
          OrderItem.persist(order, item, item.amount)
        end
      rescue ActiveRecord::RecordNotUnique => e

      end
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
end
