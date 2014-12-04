class Item < ActiveRecord::Base
  ARRAY_ATTRIBUTES = [:categories, :locations]

  attr_accessor :amount, :action_id, :mail_recommended_by

  belongs_to :shop
  has_many :actions
  has_many :order_items
  has_many :mahout_actions

  scope :available, -> { where(is_available: true) }
  scope :expired, -> { where('available_till IS NOT NULL').where('available_till <= ?', Date.current) }
  scope :in_categories, ->(categories) {
    if categories && categories.any?
      where("? <@ categories", "{#{categories.join(',')}}")
    end
  }
  scope :in_locations, ->(locations) {
    if locations && locations.any?
      where("? <@ locations", "{#{locations.join(',')}}")
    end
  }
  scope :widgetable, ->() {
    where('name IS NOT NULL AND name != \'\'').where('url IS NOT NULL AND url != \'\'').where('image_url IS NOT NULL AND image_url != \'\'').where('price IS NOT NULL AND price != 0.0')
  }

  class << self
    def disable_expired
      Item.available.expired.find_each do |item|
        item.update(is_available: false)
      end
    end

    def fetch(shop_id, item_proxy)
      item = find_or_initialize_by(shop_id: shop_id, uniqid: item_proxy.uniqid.to_s)
      item.apply_attributes(item_proxy)
    end

    def available_attributes
      attribute_names.select{|a| !['id', 'shop_id', 'uniqid'].include?(a) }
    end
  end

  def apply_attributes(item_proxy)
    self.amount = item_proxy.amount
    attrs = merge_attributes(item_proxy)

    begin
      save! if changed?
      return self
    rescue ActiveRecord::RecordNotUnique => e
      item = find_by(shop_id: shop_id, uniqid: item_proxy.uniqid.to_s)
      item.amount = item_proxy.amount
      return item
    end
  end

  def to_s
    "Item ##{id} (external #{uniqid}) #{name} at #{price}"
  end

  def widgetable?
    price.present? && name.present? && url.present? && image_url.present?
  end

  def merge_attributes(new_item)
    new_item.is_available = true if new_item.is_available.nil?

    attrs = {
                  price: ValuesHelper.present_one(new_item, self, :price),
              locations: ValuesHelper.with_contents(new_item, self, :locations),
             categories: ValuesHelper.with_contents(new_item, self, :categories),
                   tags: ValuesHelper.with_contents(new_item, self, :tags),
                   name: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :name)),
            description: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :description)),
                    url: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :url)),
              image_url: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :image_url)),
                  brand: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :brand)),
           is_available: new_item.is_available,
         available_till: ValuesHelper.present_one(new_item, self, :available_till),
             repeatable: ValuesHelper.false_one(new_item, self, :repeatable)
    }

    assign_attributes(attrs)

    self.widgetable = self.name.present? && self.url.present? && self.image_url.present?

    attrs
  end
end
