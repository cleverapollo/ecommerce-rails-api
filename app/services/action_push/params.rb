module ActionPush
  ##
  # Базовый класс ошибки при работе с событиями
  #
  class Error < StandardError;
  end

  ##
  # Ошибка входящих параметров при работе с событиями
  #
  class IncorrectParams < Error;
  end

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
    # Код триггерной рассылки
    attr_accessor :trigger_mail_code
    # Код дайджестной рассылки
    attr_accessor :digest_mail_code
    # Код показа в RTB
    attr_accessor :r46_returner_code
    # Источник
    attr_accessor :source
    # Модификация
    attr_accessor :modification

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
      extract_modification
      normalize_item_arrays and extract_items
      self
    end

    private

    # Конструктор, выполняет первоначальную проверку параметров
    #
    # @private
    # @param params [Hash] входящие параметры
    def initialize(params)
      @raw = params
      check
    end

    # Выполняет первоначальную проверку входящих параметров
    #
    # @private
    # @raise [ActionPush::IncorrectParams] исключение с сообщением
    def check
      raise ActionPush::IncorrectParams.new('Session ID not provided') if raw[:ssid].blank?
      raise ActionPush::IncorrectParams.new('Shop ID not provided') if raw[:shop_id].blank?
      raise ActionPush::IncorrectParams.new('Action not provided') if raw[:event].blank?
      raise ActionPush::IncorrectParams.new('Unknown action') unless Action::TYPES.include?(raw[:event])
      raise ActionPush::IncorrectParams.new('Unsupported action') if raw[:event] == 'rate'
      raise ActionPush::IncorrectParams.new('Incorrect rating') if raw[:rating].present? && !(1..5).include?(raw[:rating].to_i)
      raise ActionPush::IncorrectParams.new('Unknown recommender') if raw[:recommended_by].present? && !Recommender::Base::TYPES.include?(raw[:recommended_by])
    end

    # Извлекает и находит магазин из параметров
    #
    # @private
    # @raise [ActionPush::IncorrectParams] исключение, если магазин не найден
    def extract_shop
      @shop = Shop.find_by!(uniqid: raw[:shop_id])
    rescue ActiveRecord::RecordNotFound => e
      raise ActionPush::IncorrectParams.new("Shop not found: #{raw[:shop_id]}")
    end

    # Извлекает статичные поля из параметров
    #
    # @private
    def extract_static_attributes
      @action = raw[:event]
      @rating = raw[:rating].present? ? raw[:rating].to_i : nil
      @recommended_by = raw[:recommended_by]
      @order_id = raw[:order_id]
      @trigger_mail_code = raw[:trigger_mail_code]
      @digest_mail_code = raw[:digest_mail_code]
      @r46_returner_code = raw[:returner_code]
      @source = raw[:source].present? ? JSON.parse(raw[:source]) : nil
    end

    # Извлекает пользователя
    #
    # @private
    def extract_user
      user_fetcher = UserFetcher.new(external_id: raw[:user_id],
                                     email: raw[:user_email],
                                     location: raw[:user_location],
                                     shop: shop,
                                     session_code: raw[:ssid])
      @user = user_fetcher.fetch
    end


    # Извлекает модификацию отраслевого алгоритма
    def extract_modification
      if raw[:modification].present? && Recommender::Base::MODIFICATIONS.include?(raw[:modification])
        @modification = raw[:modification]
      end
    end

    # Нормализует входящие массивы
    #
    # @private
    def normalize_item_arrays
      [:item_id, :category, :price, :is_available, :amount, :locations, :name, :description, :url, :image_url, :brand, :categories, :priority, :attributes].each do |key|
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
        item_attributes = OpenStruct.new(uniqid: item_id)

        item_attributes.amount = raw[:amount][i].present? ? raw[:amount][i] : 1
        item_attributes.ignored = raw[:priority][i].present? ? raw[:priority][i] == 'ignore' : false
        item_attributes.brand = raw[:brand][i] ? StringHelper.encode_and_truncate(raw[:brand][i].mb_chars.downcase.strip) : nil

        raw_is_avalilable =  IncomingDataTranslator.is_available?(raw[:is_available][i])
        available_present = raw[:is_available].present? && raw[:is_available][i].present?

        raw_price = nil
        raw_price = raw[:price][i] if raw[:price][i].to_i > 0

        # У товара есть YML
        if shop.has_imported_yml?
          cur_item = Item.where(shop_id:shop.id, uniqid: item_id).limit(1)[0]
          if cur_item
            # товар есть в базе
            if available_present
              item_attributes.is_available=raw_is_avalilable
            else
              item_attributes.is_available = cur_item.is_available
            end
            item_attributes.price = raw_price if !cur_item.price && raw_price.to_i > 0
          else
            item_attributes.is_available = raw_is_avalilable if available_present
          end

        else

          item_attributes.is_available = raw_is_avalilable

          item_attributes.locations = raw[:locations][i].present? ? raw[:locations][i].split(',') : []
          item_attributes.price = raw_price
          item_attributes.category = raw[:category][i].to_s if raw[:category][i].present?
          item_attributes.categories = raw[:categories][i].present? ? raw[:categories][i].split(',') : []
          item_attributes.categories = (item_attributes.categories + [item_attributes.category]).uniq.compact

          item_attributes.name = raw[:name][i] ? StringHelper.encode_and_truncate(raw[:name][i]) : ''
          item_attributes.description = raw[:description][i] ? StringHelper.encode_and_truncate(raw[:description][i]) : ''

          item_attributes.barcode = raw[:barcode].present? && raw[:barcode][i].present? ? StringHelper.encode_and_truncate(raw[:barcode][i]) : nil

          item_attributes.url = raw[:url][i] ? StringHelper.encode_and_truncate(raw[:url][i], 1000) : nil
          if item_attributes.url.present? && !item_attributes.url.include?('://')
            item_attributes.url = correct_url_joiner(shop.url, item_attributes.url)
          end

          item_attributes.image_url = raw[:image_url][i] ? StringHelper.encode_and_truncate(raw[:image_url][i], 1000) : ''
          if item_attributes.image_url.present? && !item_attributes.image_url.include?('://')
            item_attributes.image_url = correct_url_joiner(shop.url, item_attributes.image_url)
          end
        end


        attributes = raw[:attributes][i].present? ? JSON.parse(raw[:attributes][i]) : {}


        # Прогрузим данные для отраслевых

        if raw[:attributes][i].present?
          # для fashion
          fashion_attributes = attributes['fashion'].present? ? attributes['fashion'] : {}
          attributes.delete('fashion')
          if fashion_attributes['gender'].present? && ['m', 'f'].include?(fashion_attributes['gender'])
            item_attributes.gender = fashion_attributes['gender']
          end

          if fashion_attributes['sizes'].present? && fashion_attributes['sizes'].is_a?(Array) && fashion_attributes['sizes'].any?
            item_attributes.sizes = fashion_attributes['sizes']
          end

          if fashion_attributes['type'].present? && SizeHelper::SIZE_TYPES.include?(fashion_attributes['type'])
            item_attributes.wear_type = fashion_attributes['type']
          end

          # для child
          child_attributes = attributes['child'].present? ? attributes['child'] : {}
          attributes.delete('child')
          if child_attributes['gender'].present? && ['m', 'f'].include?(child_attributes['gender'])
            item_attributes.gender = child_attributes['gender']
          end

          if child_attributes['sizes'].present? && child_attributes['sizes'].is_a?(Array) && child_attributes['sizes'].any?
            item_attributes.sizes = child_attributes['sizes']
          end

          if child_attributes['type'].present? && ChildHelper::ITEM_TYPES.include?(child_attributes['type'])
            item_attributes.wear_type = child_attributes['type']
          end

          if child_attributes['age'].present?
            item_attributes.age_min = child_attributes['age']['min'] if child_attributes['age']['min'].present?
            item_attributes.age_max = child_attributes['age']['max'] if child_attributes['age']['max'].present?
          end
        end

        @items << Item.fetch(shop.id, item_attributes)
      end
    rescue JSON::ParserError => e
      raise ActionPush::IncorrectParams.new(e.message)
    end

    def correct_url_joiner(shop_url, uri)
      url = ''
      if shop_url.end_with?('/') && uri.start_with?('/')
        url = shop_url[0...-1] + uri
      elsif shop_url.end_with?('/') && !uri.start_with?('/') || !shop_url.end_with?('/') && uri.start_with?('/')
        url = shop_url + uri
      elsif !shop_url.end_with?('/') && !uri.start_with?('/')
        url = shop_url + '/' + uri
      end
      url
    end
  end
end
