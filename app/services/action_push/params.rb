module ActionPush
  ##
  # Класс, проверяющий и извлекающий нужные объекты из параметров, которые приходят от магазинов
  #
  class Params
    # Входящие параметры
    attr_accessor :raw
    # Магазин
    attr_accessor :shop
    # Пользователь
    attr_accessor :user
    # Название действия
    attr_accessor :action
    # Рейтинг (только для действия rate)
    attr_accessor :rating
    # Какой рекомендер привел пользователя на товар
    attr_accessor :recommended_by
    # Массив товаров
    attr_accessor :items
    # ID заказа в магазине (только для действия purchase)
    attr_accessor :order_id
    # Дата события
    attr_accessor :date

    # Проверяет и обрабатывает параметры
    #
    # @param params [Hash] входящие параметры
    # @return [ActionPush::Params] обработанные параметры
    def self.extract(params)
      new(params).extract
    end

    # Извлекает данные из параметров
    #
    # @return [ActionPush::Params] обработанные параметры
    def extract
      extract_static_attributes
      extract_shop
      extract_user
      normalize_item_arrays and extract_items
      self
    end

    private

    # Конструктор, выполняет первоначальную проверку параметров
    #
    # @private
    # @param params [Hash] входящие параметры
    def initialize(params)
      if params[:shop_id] == 'ca4d9238983e2ec4823e8de828ead8' && params[:event] == 'purchase'
        Logger.new("#{Rails.root}/log/debug.log").debug("
          * ===================================\n
          * NEW PURCHASE PARAMS\n
          * -----------------------------------\n
          * #{params.inspect}
        ")
      end
      @raw = params
      check
    end

    # Выполняет первоначальную проверку входящих параметров
    #
    # @private
    # @raise [ArgumentError] исключение с сообщением
    def check
      raise ArgumentError.new('Session ID not provided') if raw[:ssid].blank?
      raise ArgumentError.new('Shop ID not provided') if raw[:shop_id].blank?
      raise ArgumentError.new('Action not provided') if raw[:event].blank?
      raise ArgumentError.new('Unknown action') unless Action::TYPES.include?(raw[:event])
      raise ArgumentError.new('Incorrect rating') if raw[:rating].present? and !(1..5).include?(raw[:rating])
      raise ArgumentError.new('Unknown recommender') if raw[:recommended_by].present? and !Recommender::Base::TYPES.include?(raw[:recommended_by])
    end

    # Извлекает и находит магазин из параметров
    #
    # @private
    # @raise [ArgumentError] исключение, если магазин не найден
    def extract_shop
      @shop = Shop.find_by!(uniqid: raw[:shop_id])
    rescue ActiveRecord::RecordNotFound => e
      raise ArgumentError.new("Shop not found: #{raw[:shop_id]}")
    end

    # Извлекает статичные поля из параметров
    #
    # @private
    def extract_static_attributes
      @action         = raw[:event]
      @rating         = raw[:rating]
      @recommended_by = raw[:recommended_by]
      @order_id       = raw[:order_id]
    end

    # Извлекает пользователя
    #
    # @private
    def extract_user
      user_fetcher = UserFetcher.new \
                                     uniqid: raw[:user_id],
                                     shop_id: shop.id,
                                     ssid: raw[:ssid]
      @user = user_fetcher.fetch
    end

    # Приводит входящие массивы в каноничный вид
    #
    # @private
    def normalize_item_arrays
      [:item_id, :category, :price, :is_available, :amount, :locations].each do |key|
        unless raw[key].is_a?(Array)
          raw[key] = raw[key].to_a.map(&:last)
        end
      end
    end

    # Извлекает информацию об товарах и вносит ее в базу
    #
    # @private
    def extract_items
      @items = []

      raw[:item_id].each_with_index do |item_id, i|
        category = raw[:category][i].to_s
        price = raw[:price][i]
        is_available = raw[:is_available][i].present? ? raw[:is_available][i] : true
        amount = raw[:amount].present? ? raw[:amount][i] : 1
        locations = raw[:locations][i].present? ? raw[:locations][i].split(',') : []

        item_object = OpenStruct.new(uniqid: item_id,
                                     category_uniqid: category,
                                     price: price,
                                     is_available: is_available,
                                     amount: amount,
                                     locations: locations)

        @items << Item.fetch(shop.id, item_object)
      end
    end
  end
end
