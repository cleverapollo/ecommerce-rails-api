class Item < ActiveRecord::Base
  ARRAY_ATTRIBUTES = [:categories, :locations]
  ACTION_ATTRIBUTES = [:is_available, :locations]

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

  class << self
    def disable_expired
      Item.available.expired.find_each do |item|
        item.actions.find_in_batches(batch_size: 100) do |batch|
          Action.where(id: batch.map(&:id), item_id: item.id, shop_id: item.shop_id).update_all(is_available: false)
        end

        item.update(is_available: false)
      end
    end

    def fetch(shop_id, item_proxy)
      item = find_or_initialize_by(shop_id: shop_id, uniqid: item_proxy.uniqid.to_s)

      attrs = item.merge_attributes(item_proxy)

      changed = item.is_available_changed? || item.locations_changed?

      item.amount = item_proxy.amount

      begin
        item.save!
      rescue ActiveRecord::RecordNotUnique => e
        item = find_by(shop_id: shop_id, uniqid: item_proxy.uniqid.to_s)
        item.amount = item_proxy.amount
      end

      ItemsSynchronizeWorker.perform_async(item.id, attrs) if item.persisted? && changed

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

    # REES-341.2
    if attrs[:category_uniqid].present? && attrs[:categories].none?
      attrs[:categories] = [attrs[:category_uniqid]]
    end

    assign_attributes(attrs)
    self.widgetable = self.name.present? && self.url.present? && self.image_url.present?

    attrs
  end
end
