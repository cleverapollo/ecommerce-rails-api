class Item < ActiveRecord::Base
  belongs_to :shop

  class << self
    def fetch(shop_id, item)
      i = find_or_create_by(shop_id: shop_id, uniqid: item.uniqid)
      i.update(category_uniqid: item.category_uniqid, price: item.price, is_available: item.is_available)
      i
    end
  end
end
