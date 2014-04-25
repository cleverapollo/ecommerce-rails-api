class Item < ActiveRecord::Base
  belongs_to :shop
  attr_accessor :amount

  scope :available, -> { where("is_available = true") }

  class << self
    def fetch(shop_id, item)
      i = find_or_initialize_by(shop_id: shop_id, uniqid: item.uniqid.to_s)
      i.assign_attributes \
                          category_uniqid: item.category_uniqid.present? ? item.category_uniqid : i.category_uniqid,
                          price: item.price.present? ? item.price : i.price,
                          is_available: item.is_available,
                          locations: item.locations,
                          tags: item.tags,
                          name: item.name,
                          description: item.description,
                          url: item.url,
                          image_url: item.image_url,
                          brand: item.brand,
                          widgetable: item.widgetable

      i.amount = item.amount
      if i.persisted? and i.changed?
        Action.where(item_id: i.id).update_all \
          is_available: i.is_available,
          price: i.price,
          category_uniqid: i.category_uniqid,
          locations: i.locations,
          brand: i.brand
      end
      i.save!
      i
    end
  end
end
