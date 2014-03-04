class Item < ActiveRecord::Base
  belongs_to :shop
  attr_accessor :amount

  scope :available, -> { where("is_available = true") }

  class << self
    def fetch(shop_id, item)
      i = find_or_initialize_by(shop_id: shop_id, uniqid: item.uniqid)
      i.assign_attributes(category_uniqid: item.category_uniqid, price: item.price, is_available: item.is_available)
      i.amount = item.amount
      i.save!
      i
    end
  end
end
