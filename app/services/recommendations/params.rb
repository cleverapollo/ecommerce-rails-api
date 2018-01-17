module Recommendations

  ##
  # Класс, проверяющий и извлекающий нужные объекты из параметров, которые приходят от магазинов при запросе рекомендаций
  #
  class Params
    # Входящие параметры
    attr_accessor :raw
    # Пользователь
    # @deprecated
    # @return [User]
    attr_accessor :user
    # Профиль клиента
    # @return [People::Profile]
    attr_accessor :profile
    # @return [Client]
    attr_accessor :client
    # Сессия
    # @return [Session]
    attr_accessor :session
    attr_accessor :current_session_code
    attr_accessor :request
    # @return [Shop] Магазин
    attr_accessor :shop
    # Тип вызываемого рекомендера
    attr_accessor :type
    # Массив категорий
    # @return [Array] categories
    attr_accessor :categories
    # Текущий просматриваемый товар
    # TODO: переименовать в current_item
    # @return [Item] item
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
    # Нужно ли ресайзить изображения? Если да, то до какого размера
    attr_accessor :resize_image
    # @return [Boolean] skip_niche_algorithms Включен ли отраслевой режим (выключен по умолчанию)
    attr_accessor :skip_niche_algorithms
    # @return [Boolean] track_recommender Нужно ли трекать вызов рекомендера (включен по умолчанию)
    attr_accessor :track_recommender
    # Список сегментов
    attr_accessor :segments
    # @return [Float] max_price_filter ограничитель максимальной цены рекомендуемых товаров. По-умолчанию отсутствует
    attr_accessor :max_price_filter
    # @return [Boolean] Включить подмешивание брендов
    attr_accessor :brand_promotions
    # @return [Array<ShopInventory>] Список инвентарей для подмешивания в рекомендации. Используется для popup.
    attr_accessor :shop_inventories
    # @return [Float] Средняя стоимость просматриваемых товаров за неделю
    attr_accessor :price_sensitive
    attr_accessor :price_range

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
      extract_exclude
      extract_static_attributes
      extract_shop
      extract_user
      extract_cart
      extract_item
      extract_items
      extract_categories
      extract_locations
      extract_brands
      extract_search_query
      extract_avg_viewed_price
      self
    end

    # Метод-сокращалка до ID текущего товара
    #
    # @return [Integer] ID текущего товара (если есть)
    def item_id
      item.try(:id)
    end

    # Получает список Item id
    def exclude_item_ids
      @exclude_item_ids ||= (self.exclude.present? ? shop.items.where(uniqid: exclude).pluck(:id) : [])
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
      @skip_niche_algorithms     = false
      @track_recommender         = true
      self.brand_promotions      = false
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
      raise Recommendations::IncorrectParams.new("Unknown recommender: #{raw[:recommender_type]}") unless (Recommender::Base::TYPES + %w(dynamic)).include?(raw[:recommender_type])
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
      @resize_image = raw[:resize_image] if TriggerMailing.valid_image_size?(raw[:resize_image])

      # Формируем сегменты
      if raw[:segments].present?
        self.segments = raw[:segments].map { |s| "#{s[0]}_#{s[1]}" }
      end
    end

    # Извлекает магазин
    #
    # @private
    # @raise [Recommendations::IncorrectParams] исключение с сообщением, если магазин не найден
    def extract_shop
      return if shop.present?

      unless @shop = Shop.find_by(uniqid: raw[:shop_id])
        raise Recommendations::IncorrectParams.new("Shop with ID #{raw[:shop_id]} not found")
      end

    end

    # Извлекает юзера через сессию
    #
    # @private
    # @raise [Recommendations::IncorrectParams] в случае, если не удалось найти сессию.
    def extract_user
      user_fetcher = UserFetcher.new(ssid: raw[:ssid], shop: @shop, email: raw[:email])
      @user = user_fetcher.fetch
      @session = user_fetcher.session
      @client = user_fetcher.client
      raise Recommendations::IncorrectParams.new('Client not found') if @client.blank?
      raise Recommendations::IncorrectParams.new('Invalid session') if @session.blank?

      # Достаем профиль юзера
      @profile = client.profile
    end

    # Извлекает текущий товар
    #
    # @private
    def extract_item
      if raw[:item_id].present?
        @item = Slavery.on_slave { Item.find_by(uniqid: raw[:item_id].to_s, shop_id: @shop.id) }
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

      # Выходим, если корзина пустая
      if raw[:cart_item_id].nil?
        return
      end

      # Конвертируем хеш в массив
      if raw[:cart_item_id].is_a?(Hash)
        raw[:cart_item_id] = raw[:cart_item_id].values
      end

      # Конвертируем одиночное значение в массив
      if !raw[:cart_item_id].is_a?(Array)
        raw[:cart_item_id] = [raw[:cart_item_id]]
      end

      # Находим товары
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

    # Извлекает среднюю ценю просматриваемых товаров за последнюю неделю
    def extract_avg_viewed_price
      if raw[:price_sensitive].present? && raw[:price_sensitive] && self.categories.present?
        items = ActionCl.in_date(7.days.ago..Time.now).where(shop_id: shop.id, session_id: session.id, object_type: 'Item', event: 'view').distinct.pluck(:object_id)
        self.price_sensitive = shop.items.recommendable.in_categories(self.categories).where(uniqid: items).average(:price)
        self.price_range = 0.1 if self.price_sensitive.present?
      end
    end

  end
end
