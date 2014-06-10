class Item < ActiveRecord::Base
  ACTION_ATTRIBUTES = [:is_available, :price, :category_uniqid, :locations, :brand, :repeatable]

  attr_accessor :amount, :action_id

  belongs_to :shop
  has_many :actions do
    def merge_attributes(attrs)
      update_all(attrs.select{|key, _| ACTION_ATTRIBUTES.include?(key) })
    end
  end

  scope :available, -> { where(is_available: true) }

  class << self
    def fetch(shop_id, item_proxy)
      item = find_or_initialize_by(shop_id: shop_id, uniqid: item_proxy.uniqid.to_s)

      attrs = item.merge_attributes(item_proxy)

      item.amount = item_proxy.amount

      item.save!

      item.actions.merge_attributes(attrs) if item.persisted? && item.changed?

      item
    end

    def available_attributes
      attribute_names.select{|a| !['id', 'shop_id', 'uniqid'].include?(a) }
    end
  end

  def widgetable?
    price.present? && name.present? && url.present? && image_url.present?
  end

  def attributes_for_actions
    attributes.select{|key, _| ACTION_ATTRIBUTES.include?(key.to_sym) }
  end

  def merge_attributes(new_item)
    new_item.is_available = true if new_item.is_available.nil?

    attrs = {
        category_uniqid: ValuesHelper.present_one(new_item, self, :category_uniqid),
                  price: ValuesHelper.present_one(new_item, self, :price),
              locations: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :locations)),
                   tags: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :tags)),
                   name: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :name)),
            description: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :description)),
                    url: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :url)),
              image_url: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :image_url)),
                  brand: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :brand)),
           is_available: new_item.is_available,
             repeatable: ValuesHelper.false_one(new_item, self, :repeatable)
    }

    assign_attributes(attrs)
    self.widgetable = self.name.present? && self.url.present? && self.image_url.present?

    attrs
  end
end
