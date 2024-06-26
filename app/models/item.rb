##
# Товар
#
class Item < ActiveRecord::Base
  acts_as_copy_target

  attr_accessor :amount, :action_id, :mail_recommended_by

  belongs_to :shop

  has_many :interactions, dependent: :delete_all
  has_many :order_items
  has_many :brand_campaign_purchases
  has_many :subscribe_for_product_availables, dependent: :delete_all
  has_many :subscribe_for_product_prices, dependent: :delete_all
  has_many :reputations, as: :entity

  scope :recommendable, -> { available.where(ignored: false) }
  scope :widgetable,    -> { where(widgetable: true) }
  scope :by_sales_rate, -> { order('sales_rate DESC NULLS LAST') }
  scope :available,     -> { where(is_available: true) }
  scope :discount,     -> { where(discount: true) }
  scope :not_periodic, -> { where('fmcg_periodic IS NOT TRUE AND cosmetic_periodic IS NOT TRUE AND auto_periodic IS NOT TRUE AND pets_periodic IS NOT TRUE') }


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
      where("ARRAY[?]::varchar[] #{ args[:any] ? '&&' : '<@' } location_ids OR (array_length(location_ids, 1) = 0) OR (location_ids IS NULL)", (locations.is_a?(Hash) ? locations.keys : locations))
    else
      all
    end
  }

  # Добавляет выборку с сезонностью
  scope :in_seasonality, -> { where('(seasonality IS NULL) OR (seasonality && ARRAY[?])', Date.current.month) }

  # Фильтруем по бренду
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
      cosmetic_nail
      cosmetic_nail_type
      cosmetic_nail_color
      cosmetic_perfume_aroma
      cosmetic_professional
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
      is_pets
      pets_breed
      pets_type
      pets_age
      pets_periodic
      pets_size
      is_jewelry
      jewelry_gender
      jewelry_color
      jewelry_metal
      jewelry_gem
      ring_sizes
      bracelet_sizes
      chain_sizes
      seasonality
      leftovers
      is_realty
      realty_type
      realty_space_min
      realty_space_max
      realty_space_final
      realty_action
    ].sort
  end

  class << self
    # Найти или создать товар с аттрибутами
    def fetch(shop_id, item_proxy)
      item = Slavery.on_slave { find_or_initialize_by(shop_id: shop_id, uniqid: item_proxy.uniqid.to_s) }
      item.apply_attributes(item_proxy)
    end
    # Проверка на валидность url
    def valid_url?(url)
        url_re = /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
        !url_re.match(url).nil?
    end
  end
  # Применить аттрибуты товара
  def apply_attributes(item_proxy)
    self.amount = item_proxy.amount
    self.attributes = merge_attributes(item_proxy)

    begin
      image_changed = image_url_changed?
      atomic_save! if changed?
      if widgetable? && image_changed && persisted?
        ImageDownloadLaunchWorker.perform_async(self.shop_id, [{ id: self.id, image_url: self.image_url }])
      end
      return self
    rescue ActiveRecord::RecordNotUnique => e
      item = Item.find_by(shop_id: shop_id, uniqid: item_proxy.uniqid.to_s)
      item.amount = item_proxy.amount
      return item
    end
  end

  # Назначить аттрибуты
  def merge_attributes(new_item)
    new_item.is_available = true if new_item.is_available.nil?

    # # Если урл заполнен, проверяем валидность
    # if new_item.url.present? && !Item.valid_url?(new_item.url)
    #   raise "Url not valid id: #{new_item.uniqid}, url: #{new_item.url}"
    # end

    attrs = {
        price: ValuesHelper.present_one(new_item, self, :price),
        price_margin: ValuesHelper.present_one(new_item, self, :price_margin),
        category_ids: ValuesHelper.with_contents(new_item, self, :category_ids),
        location_ids: ValuesHelper.with_contents(new_item, self, :location_ids),
        locations: ValuesHelper.with_contents(new_item, self, :locations),
        name: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :name)),
        description: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :description)),
        url: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :url)),
        image_url: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :image_url)),
        brand: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :brand)),
        is_available: new_item.is_available,
        type_prefix: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :type_prefix)),
        vendor_code: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :vendor_code)),
        model: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :model)),
        fashion_gender: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :fashion_gender)),
        fashion_wear_type: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :fashion_wear_type)),
        fashion_feature: StringHelper.encode_and_truncate(ValuesHelper.present_one(new_item, self, :fashion_feature)),
        fashion_sizes: ValuesHelper.present_one(new_item, self, :fashion_sizes),
        child_gender: ValuesHelper.present_one(new_item, self, :child_gender),
        child_age_min: ValuesHelper.present_one(new_item, self, :child_age_min),
        child_age_max: ValuesHelper.present_one(new_item, self, :child_age_max),
        cosmetic_gender: ValuesHelper.present_one(new_item, self, :cosmetic_gender),
        cosmetic_hypoallergenic: ValuesHelper.present_one(new_item, self, :cosmetic_hypoallergenic),
        cosmetic_periodic: ValuesHelper.present_one(new_item, self, :cosmetic_periodic),
        cosmetic_skin_part: ValuesHelper.present_one(new_item, self, :cosmetic_skin_part),
        cosmetic_skin_type: ValuesHelper.present_one(new_item, self, :cosmetic_skin_type),
        cosmetic_skin_condition: ValuesHelper.present_one(new_item, self, :cosmetic_skin_condition),
        cosmetic_hair_type: ValuesHelper.present_one(new_item, self, :cosmetic_hair_type),
        cosmetic_hair_condition: ValuesHelper.present_one(new_item, self, :cosmetic_hair_condition),
        cosmetic_nail: ValuesHelper.present_one(new_item, self, :cosmetic_nail),
        cosmetic_nail_type: ValuesHelper.present_one(new_item, self, :cosmetic_nail_type),
        cosmetic_nail_color: ValuesHelper.present_one(new_item, self, :cosmetic_nail_color),
        cosmetic_perfume_aroma: ValuesHelper.present_one(new_item, self, :cosmetic_perfume_aroma),
        cosmetic_perfume_family: ValuesHelper.present_one(new_item, self, :cosmetic_perfume_family),
        cosmetic_professional: ValuesHelper.present_one(new_item, self, :cosmetic_professional),
        fmcg_volume: ValuesHelper.present_one(new_item, self, :fmcg_volume),
        barcode: ValuesHelper.present_one(new_item, self, :barcode),
        is_child: ValuesHelper.present_one(new_item, self, :is_child),
        is_fashion: ValuesHelper.present_one(new_item, self, :is_fashion),
        is_cosmetic: ValuesHelper.present_one(new_item, self, :is_cosmetic),
        seasonality: ValuesHelper.present_one(new_item, self, :seasonality),
        leftovers: ValuesHelper.present_one(new_item, self, :leftovers),
        is_realty: ValuesHelper.present_one(new_item, self, :is_realty),
        realty_type: ValuesHelper.present_one(new_item, self, :realty_type),
        realty_space_min: ValuesHelper.present_one(new_item, self, :realty_space_min),
        realty_space_max: ValuesHelper.present_one(new_item, self, :realty_space_max),
        realty_space_final: ValuesHelper.present_one(new_item, self, :realty_space_final),
        realty_action: ValuesHelper.present_one(new_item, self, :realty_action),
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
    (is_fmcg && fmcg_periodic == true) || (is_cosmetic && cosmetic_periodic == true) || (is_auto? && auto_periodic?) || (is_auto? && pets_periodic?)
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
            UPDATE items SET is_available = false WHERE shop_id = #{ shop_id } AND uniqid NOT IN (SELECT temp.uniqid FROM temp_#{ shop_id }_items AS temp) AND is_available = true;
          SQL

          table.connection.execute <<-SQL
            INSERT
              INTO items (#{ columns.join(', ') })
            SELECT #{ columns.map{|c| "temp.#{ c }"}.join(', ') }
              FROM temp_#{ shop_id }_items as temp
              ON CONFLICT (shop_id, uniqid) DO UPDATE
                SET (#{ yml_update_columns.join(', ') }) =
                    (#{ yml_update_columns.map{ |c| "excluded.#{ c }" }.join(', ') })
            ;

            DROP TABLE temp_#{ shop_id }_items;
          SQL

          # обязательно делаем вакум после большого изменения данных таблицы
          # если не делать, автовакум через некоторое время будет делать его
          # с блокировкой таблицы
          #table.connection.execute 'VACUUM ANALYZE items;' unless Rails.env.test?

        rescue Exception => e
          table.connection.execute <<-SQL
            DROP TABLE IF EXISTS temp_#{ shop_id }_items;
          SQL
          raise e
        ensure
          # table.table_name = "items"
        end
      end
    end
  end

  # @param [Rees46ML::Offer] offer
  # @param [String] category
  # @return [Item]
  def self.build_by_offer(offer, category, wear_types, enable_description: false)
    new do
    # @type [Item] item
    |item|
      item.leftovers = offer.leftovers if offer.leftovers.present? && %w(lot few one).include?(offer.leftovers)
      item.uniqid = offer.id
      item.name = offer.name
      if !item.name.present? && (offer.model.present? || offer.type_prefix.present? || offer.vendor.present?)
        item.name = "#{offer.type_prefix.to_s} #{offer.vendor.to_s} #{offer.model.to_s}".strip
      end
      item.name = item.name.gsub("\u00A0", "") unless item.name.nil? # Убираем неразрывные пробелы, если есть
      item.name = item.name.truncate(250) if item.name.length > 250
      if enable_description
        item.description = offer.description
        item.description = item.description.gsub("\u00A0", "").truncate(500) unless item.description.nil? # Убираем неразрывные пробелы, если есть
      else
      item.description = ''
      end
      item.model = offer.model
      item.price = offer.price
      item.price_margin = offer.price_margin
      item.oldprice = offer.oldprice.present? ? offer.oldprice : nil
      item.discount = item.price.present? && item.oldprice.present? && item.price < item.oldprice
      item.url = offer.url
      item.image_url = offer.pictures.first
      item.image_url = item.image_url.strip if item.image_url.present?
      item.type_prefix = offer.type_prefix
      item.vendor_code = offer.vendor_code
      item.barcode = offer.barcodes.first

      # Сезонность товара
      item.seasonality = offer.seasonality.map {|s| s.to_i }.select {|s| s > 0 && s <= 12 }.uniq || nil if offer.seasonality.present?

      # Определяем тип одежды
      (item.fashion_wear_type ||= wear_types.detect { |(size_type, regexp)| regexp.match(item.name) }.try(:first)) if item.name.present?
      (item.fashion_wear_type ||= wear_types.detect { |(size_type, regexp)| regexp.match(category) }.try(:first)) if category.present?

      if offer.fashion?
        item.is_fashion = true
        item.fashion_feature = offer.fashion.feature
        item.fashion_wear_type = offer.fashion.type if offer.fashion.type
        item.fashion_gender = offer.fashion.gender.value if offer.fashion.gender && offer.fashion.gender.valid?

        if offer.fashion.gender && item.fashion_wear_type
          size_table = "SizeTables::#{ item.fashion_wear_type.camelcase }".safe_constantize

          # TODO: тут не работает unisex
          if size_table && offer.fashion.gender.value
            table = size_table.new
            _sizes = offer.fashion.sizes.map { |size|
              size.ru? ? size.num : table.value(offer.fashion.gender.value, size.region, (offer.adult? ? :adult : :child), size.num)
            }.compact
            item.fashion_sizes = _sizes && _sizes.any? ? _sizes.sort_by(&:to_i) : nil
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
      else
        item.is_child = nil
      end

      if offer.cosmetic?
        item.is_cosmetic = true
        item.cosmetic_gender = offer.cosmetic.gender.value if offer.cosmetic.gender && offer.cosmetic.gender.valid?
        item.cosmetic_hypoallergenic = offer.cosmetic.hypoallergenic
        item.cosmetic_periodic = offer.cosmetic.periodic || nil
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

        # Обрабатываем данные ногтей
        if offer.cosmetic.nail.present?
          item.cosmetic_nail = true

          # Типы ногтей
          if offer.cosmetic.nail.type.present?
            item.cosmetic_nail_type = offer.cosmetic.nail.type
            item.cosmetic_nail_color = offer.cosmetic.nail.polish_color if offer.cosmetic.nail.type == 'polish'
          end
        end
        # Парфюмерия
        if offer.cosmetic.perfume.present?
          item.cosmetic_perfume_aroma = offer.cosmetic.perfume.aroma if offer.cosmetic.perfume.aroma.present?
          item.cosmetic_perfume_family = offer.cosmetic.perfume.family if offer.cosmetic.perfume.family.present?
        end
        # Для профессионалов
        item.cosmetic_professional = offer.cosmetic.professional || nil
      else
        item.is_cosmetic = nil
      end

      if offer.fmcg?
        item.is_fmcg = true
        item.fmcg_hypoallergenic = offer.fmcg.hypoallergenic
        item.fmcg_periodic = offer.fmcg.periodic
      else
        # Обнуляем, если вдруг данные изменились
        item.is_fmcg = nil
        item.fmcg_hypoallergenic = nil
        item.fmcg_periodic = nil
      end

      if offer.pets?
        item.is_pets = true
        item.pets_periodic = offer.pets.periodic
        item.pets_breed = offer.pets.breed
        item.pets_age = offer.pets.pet_age
        item.pets_type = offer.pets.pet_type
        item.pets_size = offer.pets.pet_size
      else
        # Обнуляем, если вдруг данные изменились
        item.is_pets = nil
        item.pets_periodic = nil
        item.pets_breed = nil
        item.pets_age = nil
        item.pets_type = nil
        item.pets_size = nil
      end

      if offer.jewelry
        item.is_jewelry = true
        item.jewelry_gender  =  offer.jewelry.gender && offer.jewelry.gender.valid? ? offer.jewelry.gender.value : nil
        item.jewelry_color  = offer.jewelry.jewelry_color ? offer.jewelry.jewelry_color : nil
        item.jewelry_metal  = offer.jewelry.jewelry_metal ? offer.jewelry.jewelry_metal : nil
        item.jewelry_gem  = offer.jewelry.jewelry_gem ? offer.jewelry.jewelry_gem : nil
        item.ring_sizes = offer.jewelry.ring_sizes && offer.jewelry.ring_sizes.any? ? offer.jewelry.ring_sizes.map { |x| x.value } : nil
        item.bracelet_sizes = offer.jewelry.bracelet_sizes && offer.jewelry.bracelet_sizes.any? ? offer.jewelry.bracelet_sizes.map { |x| x.value } : nil
        item.chain_sizes = offer.jewelry.chain_sizes && offer.jewelry.chain_sizes.any? ? offer.jewelry.chain_sizes.map { |x| x.value } : nil
      else
        item.is_jewelry = nil
        item.jewelry_gender = nil
        item.jewelry_color = nil
        item.jewelry_metal = nil
        item.jewelry_gem = nil
        item.ring_sizes = nil
        item.bracelet_sizes = nil
        item.chain_sizes = nil
      end

      if offer.auto?
        item.is_auto = true
        item.auto_compatibility = {
            brands: offer.auto.compatibility.map {|c| c[:brand].downcase }.reject { |v| v.nil? || v.empty? },
            models: offer.auto.compatibility.map {|c| c[:model].downcase }.reject { |v| v.nil? || v.empty? }
        }.reject { |k,v| v.nil? || v.empty? }
        item.auto_periodic = !!offer.auto.periodic
        item.auto_vds = offer.auto.vds.map(&:downcase)
      else
        # Обнуляем, если вдруг данные изменились
        item.is_auto = nil
        item.auto_compatibility = nil
        item.auto_periodic = nil
        item.auto_vds = nil
      end

      # Недвижимость, не отмечаем нишевым без обязательных параметров
      if offer.realty? && offer.realty.type.present? && offer.realty.action.present?
        item.is_realty = true
        item.realty_type = offer.realty.type if offer.realty.type.present?
        item.realty_action = offer.realty.action if offer.realty.action.present?
        item.realty_space_min = offer.realty.space.min.to_f if offer.realty.space.present? && offer.realty.space.min.present?
        item.realty_space_max = offer.realty.space.max.to_f if offer.realty.space.present? && offer.realty.space.max.present?
        item.realty_space_final = offer.realty.space.final.to_f if offer.realty.space.present? && offer.realty.space.final.present?
      end

      item.brand = offer.vendor
      item.brand = item.brand.mb_chars.downcase.strip.normalize.to_s if item.brand.present?
      # item.brand = offer.vendor_code.mb_chars.downcase.strip.normalize.to_s if !item.brand.present? && offer.vendor_code.present? && offer.vendor_code.present? && offer.vendor_code.scan(/^[a-zA-Z0-9 ]+$/).any? # Костыль для KotoFoto, которые бренд передают в vendorCode
      item.brand_downcase = item.brand.mb_chars.downcase if item.brand.present?

      # Товарные рекомендации самого магазина
      item.shop_recommend = offer.rec.to_a if offer.rec.present? && offer.rec.to_a.any?

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
    "https://pictures.#{WhiteLabel.master_domain}/resize-images/#{dimension.split('x')[0]}/#{shop.uniqid}/#{self.id}.jpg"
  end

end
