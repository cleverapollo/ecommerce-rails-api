module Recommendations
  ##
  # Базовый класс ошибки при работе с рекомендациями
  #
  class Error < StandardError; end

  ##
  # Ошибка входящих параметров при запросе рекомендаций
  #
  class IncorrectParams < Error; end

  ##
  # Класс, проверяющий и извлекающий нужные объекты из параметров, которые приходят от магазинов при запросе рекомендаций
  #
  class Params
    # Входящие параметры
    attr_accessor :raw
    # Пользователь
    attr_accessor :user
    # Сессия
    attr_accessor :session
    # Магазин
    attr_accessor :shop
    # Тип вызываемого рекомендера
    attr_accessor :type
    # Массив категорий
    attr_accessor :categories
    # Текущий просматриваемый товар
    # TODO: переименовать в current_item
    attr_accessor :item
    # Массив ID товаров в корзине
    attr_accessor :cart_item_ids
    # Максимальное количество рекомендаций
    attr_accessor :limit
    # Массив местоположений, для которых получаем рекомендации
    attr_accessor :locations
    # Массив товаров, для ранжирования
    attr_accessor :items
    # Рекомендовать только товары с параметрами для отображения
    attr_accessor :recommend_only_widgetable
    # Товары, которые нужно исключить из рекомендаций
    attr_accessor :exclude
    # Расширенный режим ответа (передавать аттрибуты товаров)
    attr_accessor :extended

    # Проверяет и обрабатывает параметры
    #
    # @param params [Hash] входящие параметры
    # @return [Recommendations::Params] обработанные параметры
    def self.extract(params)
      new(params).extract
    end

    # Извлекает все возможные данные из входящих параметров
    #
    # @raise  [Recommendations::IncorrectParams] исключение с сообщением
    # @return [Recommendations::Params] обработанные параметры
    def extract
      extract_static_attributes
      extract_shop
      extract_user
      extract_cart
      extract_item
      extract_items
      extract_categories
      extract_locations

      self
    end

    # Метод-сокращалка до ID текущего товара
    #
    # @return [Integer] ID текущего товара (если есть)
    def item_id
      item.try(:id)
    end

    private

    # Конструктор, инициализирует аттрибуты, выполняет первоначальную проверку параметров
    #
    # @private
    # @param params [Hash] входящие параметры
    def initialize(params)
      @raw                       = params
      @categories                = []
      @locations                 = []
      @cart_item_ids             = []
      @limit                     = 5
      @recommend_only_widgetable = false
      @exclude                   = []

      check
    end

    # Выполняет первоначальную проверку входящих параметров
    #
    # @private
    # @raise [Recommendations::IncorrectParams] исключение с сообщением
    def check
      raise Recommendations::IncorrectParams.new('Session ID not provided') if raw[:ssid].blank?
      raise Recommendations::IncorrectParams.new('Shop ID not provided') if raw[:shop_id].blank?
      raise Recommendations::IncorrectParams.new('Recommender type not provided') if raw[:recommender_type].blank?
      raise Recommendations::IncorrectParams.new("Unknown recommender: #{raw[:recommender_type]}") unless Recommender::Base::TYPES.include?(raw[:recommender_type])
    end

    # Извлекает статичные поля из параметров
    #
    # @private
    def extract_static_attributes
      @type = raw[:recommender_type]
      @limit = raw[:limit].to_i if raw[:limit].present?
      @extended = raw[:extended].present?
    end

    # Извлекает магазин
    #
    # @private
    # @raise [Recommendations::IncorrectParams] исключение с сообщением, если магазин не найден
    def extract_shop
      unless @shop = Shop.find_by(uniqid: raw[:shop_id])
        raise Recommendations::IncorrectParams.new("Shop with ID #{raw[:shop_id]} not found")
      end
    end

    # Извлекает юзера через сессию
    #
    # @private
    # @raise [Recommendations::IncorrectParams] в случае, если не удалось найти сессию.
    def extract_user
      @session = Session.find_by(code: raw[:ssid])
      raise Recommendations::IncorrectParams.new('Invalid session') if @session.blank?
      @user = @session.user
    end

    # Извлекает текущий товар
    #
    # @private
    def extract_item
      if raw[:item_id].present?
        @item = Item.find_by(uniqid: raw[:item_id].to_s, shop_id: @shop.id)
      # CRUTCH: Ссаный костыль для древней версии JS SDK, которая в некоторых случаях товар передает как корзину.
      elsif @cart_item_ids.any?
        @item = Item.find(@cart_item_ids.first)
      end
    end

    # Извлекает массив ID товаров для рескоринга
    #
    # @private
    def extract_items
      if raw[:items].present?
        @items = raw[:items].split(',').map(&:to_s)
      end
    end

    # Извлекает категории: могут быть переданы скалярным значением или массивом
    #
    # @private
    def extract_categories
      @categories << raw[:category].to_s if raw[:category].present?

      if raw[:categories].present?
        @categories += raw[:categories].split(',')
      end
    end

    # Извлекает местоположения: приходят массивом
    #
    # @private
    def extract_locations
      if raw[:locations].present?
        @locations += raw[:locations].split(',')
      end
    end

    # Извлекает содержимое корзины
    #
    # @private
    def extract_cart
      [:cart_item_id].each do |key|
        unless raw[key].is_a?(Array)
          raw[key] = raw[key].to_a.map(&:last)
        end
      end

      raw[:cart_item_id].each do |i|
        if cart_item = Item.find_by(uniqid: i.to_s, shop_id: @shop.id)
          @cart_item_ids << cart_item.id
        end
      end
    end
  end
end
