module ActionPush
  ##
  # Базовый класс ошибки при работе с событиями
  #
  class Error < StandardError; end

  ##
  # Ошибка входящих параметров при работе с событиями
  #
  class IncorrectParams < Error; end

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
    # Источник
    attr_accessor :source

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
      @action            = raw[:event]
      @rating            = raw[:rating].present? ? raw[:rating].to_i : nil
      @recommended_by    = raw[:recommended_by]
      @order_id          = raw[:order_id]
      @trigger_mail_code = raw[:trigger_mail_code]
      @digest_mail_code  = raw[:digest_mail_code]
      @source            = raw[:source].present? ? JSON.parse(raw[:source]) : nil
    end

    # Извлекает пользователя
    #
    # @private
    def extract_user
      user_fetcher = UserFetcher.new(external_id: raw[:user_id],
                                     email: raw[:user_email],
                                     shop: shop,
                                     session_code: raw[:ssid])
      @user = user_fetcher.fetch
    end

    # Приводит входящие массивы в каноничный вид
    #
    # @private
    def normalize_item_arrays
      [:item_id, :category, :price, :is_available, :amount, :locations, :name, :description, :url, :image_url, :tags, :brand, :repeatable, :available_till, :categories, :priority, :attributes].each do |key|
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
        category = raw[:category][i] ? raw[:category][i].to_s : nil
        price = raw[:price][i].to_i > 0 ? raw[:price][i] : nil
        is_available = IncomingDataTranslator.is_available?(raw[:is_available][i])
        amount = raw[:amount][i].present? ? raw[:amount][i] : 1
        locations = raw[:locations][i].present? ? raw[:locations][i].split(',') : []
        tags = raw[:tags][i].present? ? raw[:tags][i].split(',') : []
        categories = raw[:categories][i].present? ? raw[:categories][i].split(',') : []
        name = raw[:name][i] ? StringHelper.encode_and_truncate(raw[:name][i]) : ''
        description = raw[:description][i] ? StringHelper.encode_and_truncate(raw[:description][i]) : ''
        url = raw[:url][i] ? StringHelper.encode_and_truncate(raw[:url][i]) : nil
        custom_attributes = raw[:attributes][i].present? ? JSON.parse(raw[:attributes][i]) : {}
        if custom_attributes.present?
          custom_attributes.each do |k, value|
            if value.is_a?(Array)
              value = value.map{|v| v.strip.mb_chars.downcase.to_s }
            else
              value = value.strip.mb_chars.downcase.to_s
            end
            custom_attributes[k] = value
          end
        end

        if url.present? && !url.include?('://')
          url = shop.url + url
        end

        image_url = raw[:image_url][i] ? StringHelper.encode_and_truncate(raw[:image_url][i]) : ''
        if image_url.present? && !image_url.include?('://')
          image_url = shop.url + image_url
        end

        brand = raw[:brand][i] ? StringHelper.encode_and_truncate(raw[:brand][i].mb_chars.downcase.strip) : ''
        repeatable = raw[:repeatable][i].present? ? raw[:repeatable][i] : false
        widgetable = name.present? && url.present? && image_url.present?
        available_till = raw[:available_till][i].present? ? Time.at(raw[:available_till][i].to_i).to_date : nil
        ignored = raw[:priority][i].present? ? raw[:priority][i] == 'ignore' : false

        item_object = OpenStruct.new(uniqid: item_id,
                                     price: price,
                                     is_available: is_available,
                                     amount: amount,
                                     locations: locations,
                                     tags: tags,
                                     categories: (categories + [category]).uniq.compact,
                                     name: name,
                                     description: description,
                                     url: url,
                                     image_url: image_url,
                                     brand: brand,
                                     repeatable: repeatable,
                                     widgetable: widgetable,
                                     available_till: available_till,
                                     ignored: ignored,
                                     custom_attributes: custom_attributes)

        @items << Item.fetch(shop.id, item_object)
      end
    rescue JSON::ParserError => e
      raise ActionPush::IncorrectParams.new(e.message)
    end
  end
end
