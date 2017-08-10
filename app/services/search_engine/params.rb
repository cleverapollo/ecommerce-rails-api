module SearchEngine

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
    # @return [Shop] shop Магазин
    attr_accessor :shop
    # Тип вызываемого поиска
    attr_accessor :type

    # Массив ID товаров в корзине
    attr_accessor :cart_item_ids

    # Максимальное количество рекомендаций
    attr_accessor :limit

    # Товары, которые нужно исключить из рекомендаций
    attr_accessor :exclude

    # Поисковый запрос
    attr_accessor :search_query

    # @return [Boolean] skip_niche_algorithms Включен ли отраслевой режим (выключен по умолчанию)
    attr_accessor :skip_niche_algorithms


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
      extract_search_query
      self
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
      @cart_item_ids             = []
      @limit                     = 20
      @exclude                   = []
      type                       = nil
      check
    end

    # Выполняет первоначальную проверку входящих параметров
    #
    # @private
    # @raise [Recommendations::IncorrectParams] исключение с сообщением
    def check
      raise SearchEngine::IncorrectParams.new('Search type not provided') if raw[:type].blank?
      raise SearchEngine::IncorrectParams.new('Session ID not provided') if raw[:ssid].blank? && raw[:email].blank?
      raise SearchEngine::IncorrectParams.new('Shop ID not provided') if raw[:shop_id].blank?
      raise SearchEngine::IncorrectParams.new("Unknown search type: #{raw[:type]}") unless SearchEngine::Base::TYPES.include?(raw[:type])
      raise SearchEngine::IncorrectParams.new("Empty search query: #{raw[:search_query]}") if StringHelper.encode_and_truncate(raw[:search_query].to_s.mb_chars.downcase.strip).blank?
    end

    # Извлекает статичные поля из параметров
    #
    # @private
    def extract_static_attributes
      @type = raw[:type] if raw[:type].present?
      @limit = raw[:limit].to_i if raw[:limit].present?
      @limit = 500 if @limit > 500 # Ограничиваем 500 рекомендаций максимум. В будущем разрешить больше для особых клиентов
      @limit = 1 if @limit < 1
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
        @session = Session.find_by_code(raw[:ssid])
        raise Recommendations::IncorrectParams.new('Invalid session') if @session.blank?
      end
      # Убедиться, что у сессии есть юзер.
      if @session.user.blank?
        @session.create_user
      end
      @user = @session.user
    end

    # Извлекает массив ID товаров, которые нужно исключить из рекомендаций
    #
    # @private
    def extract_exclude
      if raw[:exclude].present?
        @exclude = raw[:exclude].split(',').map(&:to_s)
      end
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
        end
      end
    end

  end
end
