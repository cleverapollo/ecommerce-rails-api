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
  scope :discount,     -> { where('discount IS TRUE AND discount IS NOT NULL') }

  # Фильтрация по категориям
  scope :in_categories, ->(categories, args = { any: false }) {
    if categories && categories.any?
      where("category_ids IS NOT NULL AND ARRAY[?]::varchar[] #{ args[:any] ? '&&' : '<@' } category_ids", categories)
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
    brands.flatten.any? ? where("brand_downcase in (?) and brand_downcase is not null", brands.flatten) : all
  }

  def self.yml_update_columns
    @yml_update_columns ||= %w[
      price
      price_margin
      is_available
      name
      description
      url
      image_url
      widgetable
      brand
      ignored
      type_prefix
      vendor_code
      model
      fashion_gender
      child_gender
      child_type
      child_age_min
      child_age_max
      fashion_wear_type
      fashion_feature
      fashion_sizes
      fmcg_hypoallergenic
      part_type
      skin_type
      condition
      fmcg_volume
      fmcg_periodic
      barcode
      category_ids
      location_ids
      locations
      cosmetic_gender
      cosmetic_hypoallergenic
      cosmetic_skin_part
      cosmetic_skin_type
      cosmetic_skin_condition
      cosmetic_hair_type
      cosmetic_hair_condition
      cosmetic_volume
      cosmetic_periodic
      is_cosmetic
      is_child
      is_fashion
      is_fmcg
      oldprice
      brand_downcase
      discount
      is_auto
      auto_compatibility
      auto_periodic
      auto_vds
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
    self.attributes = merge_attributes(item_proxy)

    begin
      new_record = !self.persisted?
      if changed?
        save!
        ImageDownloadLaunchWorker.perform_async(self.shop_id, [ { id: self.id, image_url: self.image_url } ]) if self.widgetable? && new_record
      end
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
        price_margin: ValuesHelper.present_one(new_item, self, :price_margin),
        category_ids: ValuesHelper.with_contents(new_item, self, :category_ids),
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
        fashion_gender: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :fashion_gender)),
        fashion_wear_type: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :fashion_wear_type)),
        fashion_feature: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :fashion_feature)),
        fashion_sizes: ValuesHelper.present_one(new_item, self, :fashion_sizes),
        child_age_min: ValuesHelper.present_one(new_item, self, :child_age_min),
        child_age_max: ValuesHelper.present_one(new_item, self, :child_age_max),
        cosmetic_hypoallergenic: ValuesHelper.present_one(new_item, self, :cosmetic_hypoallergenic),
        cosmetic_periodic: ValuesHelper.present_one(new_item, self, :cosmetic_periodic),
        part_type: ValuesHelper.present_one(new_item, self, :part_type),
        skin_type: ValuesHelper.present_one(new_item, self, :skin_type),
        condition: ValuesHelper.present_one(new_item, self, :condition),
        fmcg_volume: ValuesHelper.present_one(new_item, self, :fmcg_volume),
        barcode: ValuesHelper.present_one(new_item, self, :barcode)
    }

    # Downcased brand for brand campaign manage
    attrs[:brand_downcase] = (attrs[:brand].present? ? attrs[:brand].mb_chars.downcase : nil)

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

  # Периодичный ли товар?
  def periodic?
    (is_fmcg && fmcg_periodic == true) || (is_cosmetic && cosmetic_periodic == true) || (is_auto? && auto_periodic?)
  end

  # Гипоаллергенный ли товар?
  def hypoallergenic?
    (is_fmcg && fmcg_hypoallergenic == true) || (is_cosmetic && cosmetic_hypoallergenic == true)
  end

  # Выключает товар
  def disable!
    update(is_available: false, widgetable: false, ignored: true) if is_available == true || widgetable == true || ignored == false
  end

  # Цена товара с учетом локации
  def price_at_location(client_location = nil)
    client_location = client_location.to_s # Подстраховка
    if !locations.nil? && locations.class == Hash && locations.key?(client_location) && locations[client_location].key?('price') && locations[client_location]['price'] > 0
      locations[client_location]['price']
    else
      price
    end
  end


  def self.bulk_update(shop_id, csv_file)
    ActiveRecord::Base.connection_pool.with_connection do |conn|
      tap do |table|
        table.transaction do
          begin
            table.connection.execute <<-SQL
              DROP TABLE IF EXISTS temp_#{ shop_id }_items;
              CREATE UNLOGGED TABLE IF NOT EXISTS temp_#{ shop_id }_items(LIKE items);
            SQL

            # table.table_name = "temp_#{ shop_id }_items"
            # table.copy_from csv_file.path
            # table.table_name = "items"
            table.copy_from csv_file.path, table: "temp_#{ shop_id }_items"

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
            # table.table_name = "items"
          end
        end
      end
    end
  end

  # @param offer [Rees46ML::Offer]
  def self.build_by_offer(offer)
    new do |item|
      item.uniqid = offer.id
      item.name = offer.name
      if !item.name.present? && (offer.model.present? || offer.type_prefix.present? || offer.vendor.present?)
        item.name = "#{offer.type_prefix.to_s} #{offer.vendor.to_s} #{offer.model.to_s}".strip
      end
      item.name = item.name.gsub("\u00A0", "") unless item.name.nil? # Убираем неразрывные пробелы, если есть
      item.name = item.name.truncate(250) if item.name.length > 250
      item.description = offer.description
      item.description = item.description.gsub("\u00A0", "") unless item.description.nil? # Убираем неразрывные пробелы, если есть
      item.model = offer.model
      item.price = offer.price
      item.price_margin = offer.price_margin
      item.oldprice = offer.oldprice.present? ? offer.oldprice : nil
      item.discount = item.price.present? && item.oldprice.present? && item.price < item.oldprice
      item.url = offer.url
      item.image_url = offer.pictures.first
      item.type_prefix = offer.type_prefix
      item.vendor_code = offer.vendor_code
      item.barcode = offer.barcodes.first


      if offer.fashion?
        item.is_fashion = true
        item.fashion_feature = offer.fashion.feature
        item.fashion_wear_type = offer.fashion.type
        item.fashion_gender = offer.fashion.gender.value if offer.fashion.gender && offer.fashion.gender.valid?

        if offer.fashion.gender && offer.fashion.type
          size_table = "SizeTables::#{ offer.fashion.type.camelcase }".safe_constantize

          # TODO: тут не работает unisex
          if size_table && offer.fashion.gender.value
            table = size_table.new
            _sizes = offer.fashion.sizes.map { |size|
              size.ru? ? size.num : table.value(offer.fashion.gender.value, size.region, (offer.adult? ? :adult : :child), size.num)
            }.compact
            item.fashion_sizes = _sizes && _sizes.any? ? _sizes : nil
          end
        end
      else
        item.is_fashion = nil
      end

      if offer.child?
        item.is_child = true
        item.child_type = offer.child.type if offer.child.type && offer.child.type_valid?
        item.child_gender = offer.child.gender.value if offer.child.gender && offer.child.gender.valid?
        item.child_age_min = offer.child.age.min
        item.child_age_max = offer.child.age.max
        # item.part_type = offer.child.part_types.map(&:value) if offer.child.part_types
        # item.skin_type = offer.child.skin_types.map(&:value) if offer.child.skin_types
        # item.condition = offer.child.conditions.map(&:value) if offer.child.conditions
      else
        item.is_child = nil
      end

      if offer.cosmetic?
        item.is_cosmetic = true
        item.cosmetic_gender = offer.cosmetic.gender.value if offer.cosmetic.gender && offer.cosmetic.gender.valid?
        item.cosmetic_hypoallergenic = offer.cosmetic.hypoallergenic
        item.cosmetic_periodic = offer.cosmetic.periodic
        if offer.cosmetic.skin.present?
          if offer.cosmetic.skin.part.present? && offer.cosmetic.skin.part.to_a.any?
            item.cosmetic_skin_part = offer.cosmetic.skin.part.to_a
          end
          if offer.cosmetic.skin.type.present? && offer.cosmetic.skin.type.to_a.any?
            item.cosmetic_skin_type = offer.cosmetic.skin.type.to_a
          end
          if offer.cosmetic.skin.condition.present? && offer.cosmetic.skin.condition.to_a.any?
            item.cosmetic_skin_condition = offer.cosmetic.skin.condition.to_a
          end
        end
        if offer.cosmetic.hair.present?
          if offer.cosmetic.hair.type.present? && offer.cosmetic.hair.type.to_a.any?
            item.cosmetic_hair_type = offer.cosmetic.hair.type.to_a
          end
          if offer.cosmetic.hair.condition.present? && offer.cosmetic.hair.condition.to_a.any?
            item.cosmetic_hair_condition = offer.cosmetic.hair.condition.to_a
          end
        end
      else
        item.is_cosmetic = nil
      end

      if offer.fmcg?
        item.is_fmcg = true
        item.fmcg_hypoallergenic = offer.fmcg.hypoallergenic
        item.fmcg_periodic = offer.fmcg.periodic
      end

      if offer.auto?
        item.is_auto = true
        item.auto_compatibility = {
            brands: offer.auto.compatibility.map {|c| c[:brand].downcase }.reject { |v| v.nil? || v.empty? },
            models: offer.auto.compatibility.map {|c| c[:model].downcase }.reject { |v| v.nil? || v.empty? }
        }.reject { |k,v| v.nil? || v.empty? }
        item.auto_periodic = !!offer.auto.periodic
        item.auto_vds = offer.auto.vds.map(&:downcase)
      end

      item.brand = offer.vendor
      item.brand = item.brand.mb_chars.downcase.strip.normalize.to_s if item.brand.present?
      # item.brand = offer.vendor_code.mb_chars.downcase.strip.normalize.to_s if !item.brand.present? && offer.vendor_code.present? && offer.vendor_code.present? && offer.vendor_code.scan(/^[a-zA-Z0-9 ]+$/).any? # Костыль для KotoFoto, которые бренд передают в vendorCode
      item.brand_downcase = item.brand.mb_chars.downcase if item.brand.present?

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

  # Ссылка на отресайзенную картинку товара
  # @param dimension [String]
  # @return String
  def resized_image_by_dimension(dimension = '180x180')
    "http://pictures.rees46.com/resize-images/#{dimension.split('x')[0]}/#{shop.uniqid}/#{self.id}.jpg"
  end

end
