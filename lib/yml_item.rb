##
# Обертка над товаром из YML.
#
class YmlItem
  # args = {
  #   id: ID товара в YML,
  #   is_available: параметр available из YML,
  #   content: XML внутри блока offer из YML,
  #   categories_resolver: объект, содержащий дерево категорий
  # }
  #
  def initialize(args)
    @uniqid = args.fetch(:id)
    @is_available = args.fetch(:is_available, true)
    @content = Hash.from_xml("<item>#{args.fetch(:content)}</item>")['item']
    @categories_resolver = args.fetch(:categories_resolver)
    # В этот объект будут делегироваться вызовы аттрибутов, которых нет у данного класса
    @blank_item = Item.new
    @brands = args.fetch(:brands)
    @wear_type_dictionaries = args.fetch(:wear_type_dictionaries)
  end

  def uniqid
    @uniqid.to_s
  end

  def price
    @content.fetch('price').to_f
  end

  def categories
    if @content['categoryId'].instance_of?(Array)
      # преобразуем к простому списку категорий
      @content['categoryId'].map { |category| @categories_resolver[category] }.flatten
    else
      @categories_resolver[@content['categoryId']]
    end
  end

  def name
    name = StringHelper.encode_and_truncate(@content['name'])
    if name.nil? || name.empty?
      # Формируем название
      local_brand = StringHelper.encode_and_truncate(@content['vendor'], 255) if @content['vendor'].present?
      name = [type_prefix, local_brand, model].delete_if { |val| val.nil? || val.empty? }.join(' ')
    end
    name
  end

  def description
    StringHelper.encode_and_truncate(@content['description'])
  end

  def url
    StringHelper.encode_and_truncate(@content['url'], 2000)
  end

  def brand
    brand_name = ''
    brand_name = StringHelper.encode_and_truncate(@content['fashion']['brand'], 255) if @content['fashion'].present? && @content['fashion']['brand'].present?
    brand_name = StringHelper.encode_and_truncate(@content['child']['brand'], 255) if @content['child'].present? && @content['child']['brand'].present?
    brand_name = StringHelper.encode_and_truncate(@content['vendor'], 255) if brand_name.empty? && @content['vendor'].present?

    if brand_name.empty?
      # костыль для магазинов, принципиально не способных поставить бренд самостоятельно
      @brands.each do |brand|
        if in_name?(name, brand)
          brand_name = brand.keyword
          break
        end
      end
    end

    if brand_name.blank?
      return nil
    else
      return brand_name.downcase
    end

  end

  def image_url
    picture_attribute = @content['picture']
    picture_attribute = picture_attribute.first if picture_attribute.is_a? Array
    StringHelper.encode_and_truncate(picture_attribute, 2000)
  end

  def is_available
    @is_available != 'false'
  end

  def locations
    if @content['locations'].present? && @content['locations']['location'].present?
      locations_raw = @content['locations']['location']
      locations_raw = [locations_raw] unless locations_raw.is_a? Array
      result = {}
      locations_raw.each do |location|
        result[location['id']] = {}
        if location['price'].present?
          result[location['id']]['price'] = location['price'].to_f
        end
      end
      result
    else
      []
    end
  end

  def type_prefix
    StringHelper.encode_and_truncate(@content['typePrefix'])
  end

  def vendor_code
    StringHelper.encode_and_truncate(@content['vendorCode'])
  end

  def model
    StringHelper.encode_and_truncate(@content['model'])
  end

  def gender
    gender = nil
    # Для совместимости sex->gender
    gender = StringHelper.encode_and_truncate(@content['fashion']['sex']) if @content['fashion'].present? && @content['fashion']['sex'].present?
    gender = StringHelper.encode_and_truncate(@content['fashion']['gender']) if @content['fashion'].present? && @content['fashion']['gender'].present?
    gender = StringHelper.encode_and_truncate(@content['child']['gender']) if @content['child'].present? && @content['child']['gender'].present?
    return nil if gender==''
    gender
  end

  def wear_type
    return StringHelper.encode_and_truncate(@content['fashion']['type']) if @content['fashion'].present? && @content['fashion']['type'].present?
    return StringHelper.encode_and_truncate(@content['child']['type']) if @content['child'].present? && @content['child']['type'].present?

    # ищем тип по категории
    categories.each do |category|
      @wear_type_dictionaries.each_with_index do |type_data, _|
        if type_data[1].match(@categories_resolver.info(category)[:name])
          return type_data[0]
        end
      end
    end

    # Все еще не нашли - ищем в названии.
    @wear_type_dictionaries.each_with_index do |type_data, _|
      if type_data[1].match(name)
        return type_data[0]
      end
    end

    nil
  end

  def feature
    StringHelper.encode_and_truncate(@content['fashion']['feature']) if @content['fashion'].present? && @content['fashion']['feature'].present?
  end

  def sizes
    # @content['fashion']['sizes']['size'] if @content['fashion'].present? && @content['fashion']['sizes'].present?
    value = nil
    if @content['fashion'].present? && @content['fashion']['sizes'].present?
      value = []
      @content['fashion']['sizes']['size'].each do |val|
        value << SizeHelper.to_ru(val, SizeHelper.bad_to_default({ wear_type: wear_type, gender: gender, feature: feature }))
      end
    end

    if @content['child'].present? && @content['child']['sizes'].present?
      value = []
      @content['child']['sizes']['size'].each do |val|
        value << SizeHelper.to_ru(val, SizeHelper.bad_to_default({ wear_type: wear_type, gender: gender, feature: 'child' }))
      end
    end

    value
  end

  def age_max
    @content['child']['age']['max'].to_f if @content['child'].present? && @content['child']['age'].present? && @content['child']['age']['max'].present?
  end

  def age_min
    @content['child']['age']['min'].to_f if @content['child'].present? && @content['child']['age'].present? && @content['child']['age']['min'].present?
  end

  # Delegate all unknown calls to new item object
  def method_missing(method_name, *args, &block)
    if @blank_item.respond_to? method_name
      @blank_item.public_send(method_name)
    else
      super
    end
  end

  # Проверяет наличие бренда рекламодателя в имени айтема
  def in_name?(item_name, brand)
    !item_name.match(/\b#{brand.keyword}\b/i).nil?
  end
end
