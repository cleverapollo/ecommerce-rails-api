##
# Обработчик YML-файлов магазинов.
# Обновляет информацию о товарах. Создает товары, если их нет.
#
class YmlWorker
  class Error < StandardError; end

  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_accessor :shop

  class << self
    # Обработать все магазины с YML файлами.
    def process_all!
      Shop.with_yml.find_each do |shop|
        YmlWorker.perform_async(shop.id)
      end
    end
  end

  # Точка входа.
  # @param shop_id [Integer] ID магазина.
  def perform(shop_id)
    @shop = Shop.find(shop_id)
    process
  end

  # Обработка YML-файла магазина.
  def process
    # Обходим категории и инциализируем дерево
    build_categories_tree
    # Подготавливаем все товары магазина
    build_shop_items_cache
    # Проходим по YML-каталогу
    yml_item_catalog.each do |yml_item|
      # Парсим информаци о товаре
      p_y_i = parsed_yml_item(yml_item)

      # Достаем товар из кэша или создаем новый
      item = pop_item_from_cache(p_y_i.uniqid) || shop.items.new(uniqid: p_y_i.uniqid)

      # Передаем в него параметры из YML-файла
      item.apply_attributes(p_y_i)
    end

    # Отключаем те товары, которые отсуствуют в YML файле
    disable_remaining_in_cache

    shop.update_columns(yml_loaded: true) unless shop.yml_loaded?
  rescue YmlWorker::Error => e
    ErrorsMailer.yml_import_error('anton.zhavoronkov@mkechinov.ru', shop, e)
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

  # Возвращает каталог товаров из YML файла.
  #
  # @return [Hash] каталог товаров.
  def yml_item_catalog
    parsed_yml.fetch('yml_catalog').fetch('shop').fetch('offers').fetch('offer')
  end

  # Построить дерево категорий из YML файла.
  def build_categories_tree
    # Каждому ключу (ID категории) соответствует полный массив категорий: она сама + все родительские
    @categories_tree = {}
    categories_yml = parsed_yml.fetch('yml_catalog').fetch('shop').fetch('categories').fetch('category')
    unless categories_yml.is_a? Array
      categories_yml = [categories_yml]
    end

    loop do
      break unless categories_yml.select{|c| c['processed'] != true }.any?

      categories_yml.each do |c_y|
        next if c_y['processed'] == true
        if c_y['parentId'].blank?
          # Корневая категория
          @categories_tree[c_y['id']] = [c_y['id']]
          c_y['processed'] = true
        else
          if @categories_tree[c_y['parentId']].present?
            # Родительская категория уже в дереве?
            @categories_tree[c_y['id']] = [c_y['id']] + @categories_tree[c_y['parentId']]
            c_y['processed'] = true
          else
            # А может родительской категории не существует?
            if categories_yml.none?{|c| c['id'] == c_y['parentId']}
              @categories_tree[c_y['id']] = [c_y['id']]
              c_y['processed'] = true
            end
          end
        end
      end
    end

    @categories_tree.each do |k, v|
      v.sort!
    end
  end

  # Построить кэш всех товаров магазина.
  def build_shop_items_cache
    @shop_items = {}
    shop.items.find_each do |item|
      @shop_items[item.uniqid] = item
    end
  end

  # Получить товар из кэша. При этом он от туда удалится.
  #
  # @param id [String] ID товара.
  # @return [Item] товар.
  def pop_item_from_cache(id)
    @shop_items.delete(id)
  end

  # Выключить товары, которые остались в кэше.
  def disable_remaining_in_cache
    @shop_items.each do |_, item|
      item.disable!
    end
  end

  # Возвращает объект с содержимым YML файла. Есть кэширование, можно вызывать несколько раз.
  #
  # @return [Hash] содержимое YML файла.
  # @raise [YmlWorker::Error] ошибка получения YML файла
  def parsed_yml
    begin
      if @parsed_yml.blank?
        response = HTTParty.get(shop.yml_file_url, format: :xml)

        # Любой код ответа, кроме 200 считаем ошибкой
        if response.code != 200
          raise YmlWorker::Error.new("Плохой код ответа: #{response.code}.")
        end

        @parsed_yml = response.parsed_response
        unless @parsed_yml.is_a? Hash
          @parsed_yml = MultiXml.parse(@parsed_yml)
        end
      end

      @parsed_yml
    rescue MultiXml::ParseError => e
      raise YmlWorker::Error.new("Невалидный XML: #{e.message}.")
    end
  rescue Net::ReadTimeout
    raise YmlWorker::Error.new("Тайм-аут запроса.")
  end
end
