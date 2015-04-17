##
# Обработчик YML-файлов магазинов.
# Обновляет информацию о товарах. Создает новые товары.
# Обрабатывает SAX-парсером, т.к. на больших YML в память не помещался, поэтому DOM-парсинг убрали.
#
class YmlWorker
  # Обрабатываемая ошибка при обработке
  class Error < StandardError; end

  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  class << self
    # Обработать все магазины с YML файлами.
    def process_all
      Shop.active.connected.with_yml.find_each do |shop|
        YmlWorker.perform_async(shop.id)
      end
    end
  end

  def perform(shop_id)
    retried = false
    begin
      @shop = Shop.find(shop_id)
      @yml = Yml.new(@shop)
      process
      mark_as_loaded
    rescue YmlWorker::Error => e
      raise e if Rails.env.test?
      if retried
        Rollbar.error(e, shop_id: shop.id, shop_name: shop.name, shop_url: shop.url, shop_yml_url: shop.yml_file_url)
      else
        retried = true
        retry
      end
    end
  end

  def process
    begin
      @yml.get do |yml|
        @items_cache = ShopItemsCache.new(@shop)
        @categories_tree = CategoriesTree.new(@shop)
        worker = self # Сохраняем контекст
        Xml::Parser.new(Nokogiri::XML::Reader(yml, nil, nil, (1 << 1))) do
          inside_element 'categories' do
            for_element 'category' do
              worker.process_category(attribute('id'), attribute('parentId'), inner_xml)
            end
          end
          inside_element 'offers' do
            for_element 'offer' do
              worker.process_item(attribute('id'), attribute('available'), inner_xml)
            end
          end
        end
        disable_remaining_in_cache
      end
    rescue Nokogiri::XML::SyntaxError => e
      raise YmlWorker::Error.new("Невалидный XML: #{e.message}.")
    end
  end

  def process_category(id, parent_id, name)
    @categories_tree << { id: id, parent_id: parent_id, name: name }
  end

  def process_item(id, available, item_data)
    @categories_tree.build! unless @categories_tree.built?

    base_attributes = { 'id' => id, 'available' => available }
    item_attributes = Hash.from_xml("<item>#{item_data}</item>")['item'].merge(base_attributes)
    # Парсим информаци о товаре
    p_y_i = parsed_yml_item(item_attributes)

    # Достаем товар из кэша или создаем новый
    item = @items_cache.pop(p_y_i.uniqid)
    item = @shop.items.new(uniqid: p_y_i.uniqid) if item.blank?

    # Передаем в него параметры из YML-файла
    item.apply_attributes(p_y_i)
  end

  # Выключить товары, которые остались в кэше.
  def disable_remaining_in_cache
    @items_cache.each{|item| item.disable! }
  end

  # Распарсить информацию о товаре из YML и вернуть в удобоваримом для нас виде.
  #
  # @param y_i [Hash] товар из YML
  # @return [OpenSturct] обертка над товаром
  def parsed_yml_item(y_i)
    OpenStruct.new(
      uniqid: y_i.fetch('id').to_s,
      price: y_i.fetch('price').to_f,
      categories: [@categories_tree[y_i['categoryId']]].flatten,
      name: y_i['name'].to_s.truncate(250),
      description: y_i['description'].to_s.truncate(250),
      url: y_i['url'].to_s.truncate(250),
      image_url: (y_i['picture'].present? && y_i['picture'].is_a?(Array)) ? y_i['picture'].first.to_s.truncate(250) : y_i['picture'].to_s.truncate(250),
      is_available: y_i['available'] != 'false'
    )
  end

  def mark_as_loaded
    @shop.update_columns(yml_loaded: true, last_valid_yml_file_loaded_at: Time.current)
  end
end
