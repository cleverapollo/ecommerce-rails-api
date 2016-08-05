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
    attr_accessor :brands
    # Массив товаров, для ранжирования
    attr_accessor :items
    # Рекомендовать только товары с параметрами для отображения
    attr_accessor :recommend_only_widgetable
    # Товары, которые нужно исключить из рекомендаций
    attr_accessor :exclude
    # Расширенный режим ответа (передавать аттрибуты товаров)
    attr_accessor :extended
    # Маркет отраслевого алгоритма
    attr_accessor :search_query
    # В рекомендациях участвуют только акционные товары со скидкой
    attr_accessor :discount

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
      extract_brands
      extract_exclude
      extract_search_query
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
      @brands                    = []
      @cart_item_ids             = []
      @limit                     = 8
      @recommend_only_widgetable = false
      if params[:extended].present?
        @recommend_only_widgetable = true
      end
      @exclude                   = []
      check
    end

    # Выполняет первоначальную проверку входящих параметров
    #
    # @private
    # @raise [Recommendations::IncorrectParams] исключение с сообщением
    def check
      raise Recommendations::IncorrectParams.new('Session ID not provided') if raw[:ssid].blank? && raw[:email].blank?
      raise Recommendations::IncorrectParams.new('Shop ID not provided') if raw[:shop_id].blank?
      raise Recommendations::IncorrectParams.new('Recommender type not provided') if raw[:recommender_type].blank?
      raise Recommendations::IncorrectParams.new("Unknown recommender: #{raw[:recommender_type]}") unless Recommender::Base::TYPES.include?(raw[:recommender_type])
      raise Recommendations::IncorrectParams.new("Empty search query: #{raw[:search_query]}") if raw[:recommender_type] == 'search' && StringHelper.encode_and_truncate(raw[:search_query].to_s.mb_chars.downcase.strip).blank?
    end

    # Извлекает статичные поля из параметров
    #
    # @private
    def extract_static_attributes
      @type = raw[:recommender_type]
      @limit = raw[:limit].to_i if raw[:limit].present?
      @limit = 500 if @limit > 500 # Ограничиваем 500 рекомендаций максимум. В будущем разрешить больше для особых клиентов
      @limit = 1 if @limit < 1
      @extended = raw[:extended].present?
      @discount = raw[:discount].present?
    end

    # Извлекает магазин
    #
    # @private
    # @raise [Recommendations::IncorrectParams] исключение с сообщением, если магазин не найден
    def extract_shop
      unless @shop = Shop.find_by(uniqid: raw[:shop_id])
        raise Recommendations::IncorrectParams.new("Shop with ID #{raw[:shop_id]} not found")
      end

      # TODO после теста ЦУМа убрать
      @limit = 20 if @shop.id == 992

    end

    # Извлекает юзера через сессию
    #
    # @private
    # @raise [Recommendations::IncorrectParams] в случае, если не удалось найти сессию.
    def extract_user
      if raw[:email].present?
        email = IncomingDataTranslator.email(raw[:email])
        client = Client.find_by email: email, shop_id: @shop.id
        if client.nil?
          begin
            client = Client.create!(shop_id: @shop.id, email: email, user_id: User.create.id)
          rescue # Concurrency?
            client =  Client.find_by email: email, shop_id: @shop.id
          end
        end
        raise Recommendations::IncorrectParams.new('Client not found') if client.blank?
        @session = Session.find_by user_id: client.user_id
        if @session.nil?
          @session = Session.create user_id: client.user_id
        end
      else
        @session = Session.find_by(code: raw[:ssid])
        raise Recommendations::IncorrectParams.new('Invalid session') if @session.blank?
      end
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

    # Извлекает массив ID товаров, которые нужно исключить из рекомендаций
    #
    # @private
    def extract_exclude
      if raw[:exclude].present?
        @exclude = raw[:exclude].split(',').map(&:to_s)
      end
    end

    # Извлекает категории: могут быть переданы скалярным значением или массивом
    #
    # @private
    def extract_categories
      @categories << raw[:category].to_s if raw[:category].present?

      if raw[:categories].present?
        @categories += raw[:categories].to_s.split(',')
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

    # Извлекает бренды: приходят массивом
    #
    # @private
    def extract_brands
      @brands += raw[:brands].split(',').map{ |s| StringHelper.encode_and_truncate(s.mb_chars.downcase.strip) } if raw[:brands].present?
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


    def extract_search_query
      if raw[:search_query].present?
        q = StringHelper.encode_and_truncate(raw[:search_query].to_s.mb_chars.downcase.strip)
        if q.present?
          @search_query = q
          SearchQuery.find_or_create_by user_id: @user.id, shop_id: @shop.id, date: Date.current, query: @search_query
        end
      end
    end


  end
end
