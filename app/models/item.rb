##
# Товар
#
class Item < ActiveRecord::Base


  attr_accessor :amount, :action_id, :mail_recommended_by

  belongs_to :shop
  has_many :actions
  has_many :order_items
  has_many :brand_campaign_purchases

  scope :recommendable, -> { available.where(ignored: false) }
  scope :available, -> { where(is_available: true) }
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
    where(widgetable:true)
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

  scope :by_sales_rate, -> { order('sales_rate DESC NULLS LAST') }

  class << self

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

  # Выключает товар
  def disable!
    update(is_available: false, widgetable: false) if is_available == true || widgetable == true
  end

  # Цена в определенном городе
  def price_in(location)
    locations[location].try(:price) || self.price
  end

end
