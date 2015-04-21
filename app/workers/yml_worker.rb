##
# Обработчик YML-файлов магазинов.
# Обновляет информацию о товарах. Создает новые товары.
# Обрабатывает SAX-парсером, т.к. на больших YML в память не помещался, поэтому DOM-парсинг убрали.
#
class YmlWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  XML_READER_PARAMS = [nil, nil, (1 << 1)]

  attr_reader :shop, :yml

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
      @yml = Yml.new(shop)
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

  def items_cache
    @items_cache ||= ShopItemsCache.new(shop)
  end

  def categories_tree
    @categories_tree ||= CategoriesTree.new(shop)
  end

  def process
    begin
      yml.get do |yml|
        worker = self # Сохраняем контекст
        Xml::Parser.new(Nokogiri::XML::Reader(yml, *XML_READER_PARAMS)) do
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
    rescue Yml::NotRespondingError => e
      raise YmlWorker::Error.new("Плохой код ответа.")
    rescue Nokogiri::XML::SyntaxError => e
      raise YmlWorker::Error.new("Невалидный XML: #{e.message}.")
    end
  end

  def process_category(id, parent_id, name)
    categories_tree << { id: id, parent_id: parent_id, name: name }
  end

  def process_item(id, available, item_data)
    yml_item = YmlItem.new(id: id,
                           is_available: available,
                           content: item_data,
                           categories_resolver: categories_tree)

    # Достаем товар из кэша или создаем новый
    item = items_cache.pop(yml_item.uniqid) || shop.items.new(uniqid: yml_item.uniqid)

    # Передаем в него параметры из YML-файла
    item.apply_attributes(yml_item)
  end

  # Выключить товары, которые остались в кэше.
  def disable_remaining_in_cache
    items_cache.each{|item| item.disable! }
  end

  def mark_as_loaded
    shop.update_columns(yml_loaded: true, last_valid_yml_file_loaded_at: Time.current)
  end

  # Обрабатываемая ошибка при обработке
  class Error < StandardError; end
end
