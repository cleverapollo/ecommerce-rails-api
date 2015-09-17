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
      if YmlTimeLock.new.process_available?
        YmlTimeLock.new.start_processing!
        Shop.active.connected.with_valid_yml.where(shard: SHARD_ID).find_each do |shop|
          if shop.last_valid_yml_file_loaded_at.blank? || shop.last_valid_yml_file_loaded_at < (DateTime.current - shop.yml_load_period.hours)
            YmlWorker.perform_async(shop.id)
          end
        end
        YmlTimeLock.new.stop_processing!
      end
    end

    # # Обработать приоритетные магазины
    def process_priority
    #   Shop.active.connected.with_valid_yml.where(shard: SHARD_ID).find_each do |shop|
    #     YmlWorker.perform_async(shop.id)
    #   end
    end

  end

  def perform(shop_id)
    retried = false
    begin
      @shop = Shop.find(shop_id)
      @yml = Yml.new(shop)
      process
    rescue YmlWorker::Error => e
      raise e if Rails.env.test?
      if retried
        @shop.increment_yml_errors!
        if @shop.yml_errors >= 5
          ErrorsMailer.yml_off(@shop).deliver_now
        else
          ErrorsMailer.yml_url_not_respond(@shop).deliver_now if (e.to_s == 'Плохой код ответа.')
          ErrorsMailer.yml_import_error(@shop, e.to_s).deliver_now if e.to_s == ('Не обнаружено XML-файла в архиве.')
          ErrorsMailer.yml_import_error(@shop, "Невалидный XML.").deliver_now if e.to_s.include?('Невалидный XML:')
        end
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

  def brands_cache
    @brands_cache ||= Brand.all
  end

  def wear_type_dictionaries
    # Объединенные по типам слова для матчинга
    @wear_type_dictionaries ||=
        SizeHelper::SIZE_TYPES.map{|size_type| [size_type, Regexp.union(WearTypeDictionary.by_type(size_type).pluck(:word)
                                                                        .map{|word| Regexp.new(word, Regexp::IGNORECASE)})]}.to_h
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
        mark_as_loaded
        disable_remaining_in_cache
      end
    rescue Yml::NotRespondingError => e
      raise YmlWorker::Error.new("Плохой код ответа.")
    rescue Yml::NoXMLFileInArchiveError
      raise YmlWorker::Error.new("Не обнаружено XML-файла в архиве.")
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
                           categories_resolver: categories_tree,
                           brands:brands_cache,
                           wear_type_dictionaries:wear_type_dictionaries)

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
    shop.update_columns(yml_loaded: true, last_valid_yml_file_loaded_at: Time.current, yml_errors: 0)
  end

  # Обрабатываемая ошибка при обработке
  class Error < StandardError; end
end
