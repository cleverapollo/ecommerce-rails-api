##
# Товар
#
class Item < ActiveRecord::Base
  acts_as_copy_target

  attr_accessor :amount, :action_id, :mail_recommended_by

  belongs_to :shop

  has_many :actions
  has_many :order_items
  has_many :brand_campaign_purchases

  scope :recommendable, -> { available.where(ignored: false) }
  scope :widgetable,    -> { where(widgetable:true) }
  scope :by_sales_rate, -> { order('sales_rate DESC NULLS LAST') }
  scope :available,     -> { where(is_available: true) }

  # Фильтрация по категориям
  scope :in_categories, ->(categories, args = { any: false }) {
    if categories && categories.any?
      where("ARRAY[?]::varchar[] #{ args[:any] ? '&&' : '<@' } category_ids", categories)
    else
      all
    end
  }

  # Фильтрация по городам
  scope :in_locations, ->(locations, args = { any: true }) {
    if locations && locations.any?
      where("ARRAY[?]::varchar[] #{ args[:any] ? '&&' : '<@' } location_ids", (locations.is_a?(Hash) ? locations.keys : locations))
    else
      all
    end
  }

  scope :by_brands, ->(*brands) {
    brands.flatten.any? ? where("brand in (?)", brands.flatten) : all
  }

  def self.yml_update_columns
    @yml_update_columns ||= %w[
      price
      is_available
      name
      description
      url
      image_url
      widgetable
      brand
      categories
      ignored
      type_prefix
      vendor_code
      model
      gender
      wear_type
      feature
      sizes
      age_min
      age_max
      hypoallergenic
      part_type
      skin_type
      condition
      volume
      periodic
      barcode
      category_ids
      location_ids
    ].sort
  end

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

  # Назначить аттрибуты
  # deprecated
  def merge_attributes(new_item)
    new_item.is_available = true if new_item.is_available.nil?

    attrs = {
        price: ValuesHelper.present_one(new_item, self, :price),
        categories: ValuesHelper.with_contents(new_item, self, :categories),
        name: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :name)),
        description: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :description)),
        url: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :url)),
        image_url: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :image_url)),
        brand: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :brand)),
        is_available: new_item.is_available,
        ignored: new_item.ignored.nil? ? false : new_item.ignored,
        type_prefix: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :type_prefix)),
        vendor_code: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :vendor_code)),
        model: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :model)),
        gender: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :gender)),
        wear_type: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :wear_type)),
        feature: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :feature)),
        sizes: ValuesHelper.present_one(new_item, self, :sizes),
        age_min: ValuesHelper.present_one(new_item, self, :age_min),
        age_max: ValuesHelper.present_one(new_item, self, :age_max),
        hypoallergenic: ValuesHelper.present_one(new_item, self, :hypoallergenic),
        periodic: ValuesHelper.present_one(new_item, self, :periodic),
        part_type: ValuesHelper.present_one(new_item, self, :part_type),
        skin_type: ValuesHelper.present_one(new_item, self, :skin_type),
        condition: ValuesHelper.present_one(new_item, self, :condition),
        volume: ValuesHelper.present_one(new_item, self, :volume),
        barcode: ValuesHelper.present_one(new_item, self, :barcode)
    }

    assign_attributes(attrs)

    self.widgetable = self.name.present? && self.url.present? && self.image_url.present? && self.price.present?

    attrs
  end

  def to_s
    "Item ##{id} (external #{uniqid}) #{name} at #{price}"
  end

  # Доступен для отображения?
  def widgetable?
    !!widgetable || (price.present? && name.present? && url.present? && image_url.present?)
  end

  # Выключает товар
  def disable!
    update(is_available: false, widgetable: false) if is_available == true || widgetable == true
  end

  def self.bulk_update(shop_id, csv_file)
    tap do |table|
      begin
        table.connection.execute <<-SQL
          DROP TABLE IF EXISTS temp_#{ shop_id }_items;
          CREATE UNLOGGED TABLE IF NOT EXISTS temp_#{ shop_id }_items(LIKE items);
        SQL

        table.table_name = "temp_#{ shop_id }_items"
        table.copy_from csv_file.path
        table.table_name = "items"

        columns = table.columns.map(&:name).reject{ |c| c == 'id' }

        table.connection.execute <<-SQL
          UPDATE items
             SET (#{ yml_update_columns.join(', ') }) = 
                 (#{ yml_update_columns.map{ |c| "temp.#{ c }" }.join(', ') })
            FROM temp_#{ shop_id }_items AS temp
           WHERE temp.shop_id = items.shop_id
             AND temp.uniqid = items.uniqid;

          UPDATE items
             SET is_available = false
           WHERE shop_id = #{ shop_id }
             AND uniqid NOT IN (SELECT temp.uniqid FROM temp_#{ shop_id }_items AS temp);

          DELETE
            FROM temp_#{ shop_id }_items
           WHERE uniqid in (SELECT items.uniqid FROM items WHERE items.shop_id = #{ shop_id });

          INSERT
            INTO items (#{ columns.join(', ') })
          SELECT #{ columns.map{|c| "temp.#{ c }"}.join(', ') }
            FROM temp_#{ shop_id }_items as temp;

          DROP TABLE temp_#{ shop_id }_items;
        SQL
      ensure
        table.table_name = "items"
      end
    end
  end

  def self.build_by_offer(offer)
    new do |item|
      item.uniqid = offer.id
      item.name = offer.name
      item.description = offer.description
      item.model = offer.model
      item.price = offer.price
      item.url = offer.url
      item.image_url = offer.pictures.first
      item.type_prefix = offer.type_prefix
      item.vendor_code = offer.vendor_code
      item.barcode = offer.barcodes.first

      if offer.fashion?
        item.feature = offer.fashion.feature
        item.wear_type = offer.type
        item.brand = offer.fashion.brand
        item.gender = offer.fashion.gender.value if offer.fashion.gender

        size_table = "SizeTables::#{ offer.type.camelcase }".constantize.new
        item.sizes = offer.fashion.sizes.map { |size|
          size_table.value(offer.gender.value, size.region, (offer.adult? ? :adult : :child), size.value)
        }.compact
      elsif offer.child?
        item.brand = offer.child.brand
        item.hypoallergenic = offer.child.hypoallergenic
        item.gender = offer.child.gender.value if offer.child.gender
        item.periodic = offer.child.periodic
        item.age_min = offer.child.age.min
        item.age_max = offer.child.age.max
        item.part_type = offer.child.part_types.map(&:value) if offer.child.part_types
        item.skin_type = offer.child.skin_types.map(&:value) if offer.child.skin_types
        item.condition = offer.child.conditions.map(&:value) if offer.child.conditions
      elsif offer.cosmetic?
        item.brand = offer.cosmetic.brand
        item.gender = offer.cosmetic.gender.value if offer.cosmetic.gender
        item.hypoallergenic = offer.cosmetic.hypoallergenic
        item.periodic = offer.cosmetic.periodic
        item.part_type = offer.cosmetic.part_types.map(&:value) if offer.cosmetic.part_types
        item.skin_type = offer.cosmetic.skin_types.map(&:value) if offer.cosmetic.skin_types
        item.condition = offer.cosmetic.conditions.map(&:value) if offer.cosmetic.conditions
      end

      # TODO : item.volume = offer.volume

      item.is_available = !!offer.available
      item.ignored = !!offer.ignored
      item.widgetable = item.name.present? &&
                        item.url.present? &&
                        item.image_url.present? &&
                        item.price.present?
    end
  end

  def self.csv_header
    @csv_header ||= Item.columns.map(&:name)
  end

  def csv_row
    Item.columns.map do |column|
      value = self[column.name]

      if value.nil?
        column.default
      else
        column.cast_type.type_cast_for_database(value)
      end
    end
  end
end
