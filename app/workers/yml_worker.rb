##
# Обработчик YML-файлов магазинов.
# Обновляет информацию о товарах.
#
class YmlWorker
  class Error < StandardError; end

  include Sidekiq::Worker
  sidekiq_options retry: false, queue: 'long'

  attr_reader :shop

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
      return false unless yml_exists?
      download
      process
      delete
      mark_as_loaded
    rescue YmlWorker::Error => e
      if retried
        Rollbar.error(e, shop_id: shop.id, shop_name: shop.name, shop_url: shop.url, shop_yml_url: shop.yml_file_url)
      else
        retried = true
        retry
      end
    end
  end

  def download
    delete
    `curl #{curl_options} -o #{file_name} #{shop.yml_file_url}`
  end

  def curl_options
    '--connect-timeout 60 --max-time 1800'
  end

  def process
    begin
      build_shop_items_cache
      worker = self
      Xml::Parser.new(Nokogiri::XML::Reader(File.open(file_name, 'rb'), nil, nil, (1 << 1))) do
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
    rescue Nokogiri::XML::SyntaxError => e
      raise YmlWorker::Error.new("Невалидный XML: #{e.message}.")
    end
  end

  def yml_exists?
    `curl #{curl_options} --head #{shop.yml_file_url}`.include?('200')
  end

  def process_category(id, parent_id, name)
    @categories_from_yml ||= []
    @categories_from_yml << { id: id, parent_id: parent_id, name: name.to_s.truncate(250), processed: false }
  end

  def ensure_categories_tree_is_built
    build_categories_tree unless @categories_tree_is_built
  end

  def build_categories_tree
    @shop_items_categories_cache = {}
    @shop.item_categories.find_each do |item_category|
      @shop_items_categories_cache[item_category.external_id] = item_category
    end

    @categories_from_yml.each do |category_yml|
      category = @shop_items_categories_cache[category_yml[:id].to_s] || @shop.item_categories.new(external_id: category_yml[:id].to_s)
      category.parent_external_id = category_yml[:parent_id].to_s
      category.name = category_yml[:name]
      begin
        category.save! if category.changed?
      rescue ActiveRecord::RecordNotUnique
      end
    end

    # Каждому ключу (ID категории) соответствует полный массив категорий: она сама + все родительские
    @categories_tree = {}
    loop do
      break unless @categories_from_yml.select{|c| c[:processed] != true }.any?

      @categories_from_yml.each do |c_y|
        next if c_y[:processed] == true
        if c_y[:parent_id].blank?
          # Корневая категория
          @categories_tree[c_y[:id]] = [c_y[:id]]
          c_y[:processed] = true
        else
          if @categories_tree[c_y[:parent_id]].present?
            # Родительская категория уже в дереве?
            @categories_tree[c_y[:id]] = [c_y[:id]] + @categories_tree[c_y[:parent_id]]
            c_y[:processed] = true
          else
            # А может родительской категории не существует?
            if @categories_from_yml.none?{|c| c[:id] == c_y[:parent_id]}
              @categories_tree[c_y[:id]] = [c_y[:id]]
              c_y[:processed] = true
            end
          end
        end
      end
    end

    @categories_tree.each do |k, v|
      v.sort!
    end

    @categories_tree_is_built = true
  end

  def build_shop_items_cache
    if items_cache_mode == :set
      @shop_items = Set.new
      shop.items.select(:id, :uniqid).find_each do |item|
        @shop_items.add(item[:uniqid])
      end
    elsif items_cache_mode == :hash
      @shop_items = {}
      shop.items.find_each do |item|
        @shop_items[item.uniqid] = item
      end
    end
  end

  def items_cache_mode
    return :hash
    if @items_cache_mode.blank?
      @items_cache_mode = shop.items.recommendable.count > 200_000 ? :set : :hash
    end
    @items_cache_mode
  end

  def process_item(id, available, item_data)
    ensure_categories_tree_is_built

    base_attributes = { 'id' => id, 'available' => available }
    item_attributes = Hash.from_xml("<item>#{item_data}</item>")['item'].merge(base_attributes)
    # Парсим информаци о товаре
    p_y_i = parsed_yml_item(item_attributes)

    # Достаем товар из кэша или создаем новый
    item = pop_item_from_cache(p_y_i.uniqid)
    item = shop.items.new(uniqid: p_y_i.uniqid) if item.blank?

    # Передаем в него параметры из YML-файла
    item.apply_attributes(p_y_i)
  end

  # Получить товар из кэша. При этом он от туда удалится.
  #
  # @param id [String] uniqid товара.
  # @return [Item] товар.
  def pop_item_from_cache(uniqid)
    if items_cache_mode == :set
      @shop_items.delete(uniqid)
      shop.items.find_by(uniqid: uniqid)
    elsif items_cache_mode == :hash
      @shop_items.delete(uniqid)
    end
  end

  # Выключить товары, которые остались в кэше.
  def disable_remaining_in_cache
    if items_cache_mode == :set
      @shop_items.each do |uniqid|
        shop.items.find_by(uniqid: uniqid).disable!
      end
    elsif items_cache_mode == :hash
      @shop_items.each do |_, item|
        item.disable!
      end
    end
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

  def delete
    File.delete(file_name) if File.exist?(file_name)
  end

  def file_name
    "#{Rails.root}/tmp/ymls/#{shop.id}_yml.xml"
  end

  def mark_as_loaded
    shop.update_columns(yml_loaded: true, last_valid_yml_file_loaded_at: Time.current)
  end
end
