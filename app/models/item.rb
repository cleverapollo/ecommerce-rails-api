##
# Товар
#
class Item < ActiveRecord::Base
  attr_accessor :amount, :action_id, :mail_recommended_by

  belongs_to :shop
  has_many :actions
  has_many :order_items
  has_many :mahout_actions
  has_many :advertiser_purchases

  scope :recommendable, -> { available.where(ignored: false) }
  scope :available, -> { where(is_available: true) }
  scope :expired, -> { where('available_till IS NOT NULL').where('available_till <= ?', Date.current) }
  # Фильтрация по категориям
  scope :in_categories, ->(categories, args = {}) {
    if categories && categories.any?
      operator = args[:any] ? '&&' : '<@'
      where("? #{operator} categories", "{#{categories.join(',')}}")
    end
  }
  # Фильтрация по городам
  scope :in_locations, ->(locations) {
    if locations && locations.any?
      locations = locations.keys if locations.is_a? Hash
      where("locations ?| array[#{locations.map { |l| "'#{l}'" }.join(',')}]")
    end
  }
  # Доступные для отображения
  scope :widgetable, ->() {
    where('name IS NOT NULL AND name != \'\'').where('url IS NOT NULL AND url != \'\'').where('image_url IS NOT NULL AND image_url != \'\'').where('price IS NOT NULL AND price != 0.0')
  }
  # Фильтрация по кастомным аттрибутам
  scope :by_ca, ->(params) {
    result = self
    params.each do |key, value|
      value = [value] unless value.is_a? Array
      value = value.map { |v| "'#{v}'" }.join(', ')
      result = result.where("custom_attributes ? '#{key}'").where("custom_attributes->'#{key}' ?| array[#{value}]")
    end
    result
  }

  class << self
    # Отключаем протухшие туры и купоны – товары со сроком годности
    def disable_expired
      Item.available.expired.find_each do |item|
        item.update(is_available: false)
      end
    end

    # Найти или создать товар с аттрибутами
    def fetch(shop_id, item_proxy)
      item = find_or_initialize_by(shop_id: shop_id, uniqid: item_proxy.uniqid.to_s)
      item.apply_attributes(item_proxy)
    end
  end

  # Применить аттрибуты товара
  def apply_attributes(item_proxy)
    self.amount = item_proxy.amount
    attrs = merge_attributes(item_proxy)

    begin
      save! if changed?
      return self
    rescue ActiveRecord::RecordNotUnique => e
      item = Item.find_by(shop_id: shop_id, uniqid: item_proxy.uniqid.to_s)
      item.amount = item_proxy.amount
      return item
    end
  end

  def to_s
    "Item ##{id} (external #{uniqid}) #{name} at #{price}"
  end

  # Доступен для отображения?
  def widgetable?
    price.present? && name.present? && url.present? && image_url.present?
  end

  # Назначить аттрибуты
  def merge_attributes(new_item)
    new_item.is_available = true if new_item.is_available.nil?
    self.custom_attributes = new_item.custom_attributes || {}
    self.locations = ItemLocationsMerger.merge(self.locations, new_item.locations)

    attrs = {
        price: ValuesHelper.present_one(new_item, self, :price),
        categories: ValuesHelper.with_contents(new_item, self, :categories),
        tags: ValuesHelper.with_contents(new_item, self, :tags),
        name: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :name)),
        description: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :description)),
        url: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :url)),
        image_url: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :image_url)),
        brand: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :brand)),
        is_available: new_item.is_available,
        available_till: ValuesHelper.present_one(new_item, self, :available_till),
        repeatable: ValuesHelper.false_one(new_item, self, :repeatable),
        ignored: new_item.ignored.nil? ? false : new_item.ignored,
        type_prefix: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :type_prefix)),
        vendor_code: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :vendor_code)),
        model: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :model)),
        gender: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :gender)),
        wear_type: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :wear_type)),
        feature: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :feature)),
        sizes: ValuesHelper.with_contents(new_item, self, :sizes)
    }

    assign_attributes(attrs)

    self.widgetable = self.name.present? && self.url.present? && self.image_url.present?

    attrs
  end

  # Выключает товар
  def disable!
    update(is_available: false) if is_available == true
  end

  # Цена в определенном городе
  def price_in(location)
    locations[location].try(:price) || self.price
  end
end
