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
    # @return [Shop] Магазин
    attr_accessor :shop
    # @return [User] Пользователь
    attr_accessor :user
    # @return [Client] Клиент
    attr_accessor :client
    # @return [Session]
    attr_accessor :session
    # @return [String] Уникальный код сессии хранимый до закрытия браузера
    attr_accessor :current_session_code
    # @return [ActionDispatch::Request]
    attr_accessor :request
    # Название действия
    attr_accessor :action
    # Рейтинг (только для действия rate)
    attr_accessor :rating
    # Какой рекомендер привел пользователя на товар
    attr_accessor :recommended_by
    attr_accessor :recommended_code
    # Массив товаров
    attr_accessor :items
    # @return [ItemCategory]
    attr_accessor :category
    # ID заказа в магазине (только для действия purchase)
    attr_accessor :order_id
    # Цена заказа
    attr_accessor :order_price
    # Дата события
    attr_accessor :date
    # Код триггерной рассылки
    attr_accessor :trigger_mail_code
    # Код дайджестной рассылки
    attr_accessor :digest_mail_code
    # Код показа в RTB
    attr_accessor :r46_returner_code
    # Код триггерной web push рассылки
    attr_accessor :web_push_trigger_code
    # Код дайджестной web push рассылки
    attr_accessor :web_push_digest_code
    # Источник
    attr_accessor :source
    # Список сегментов
    attr_accessor :segments

    # Кастомные параметры отраслевых
    attr_accessor :niche_attributes

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
      extract_shop if shop.nil?
      extract_static_attributes
      extract_user
      normalize_item_arrays and extract_items
      extract_category
      track_mytoys_trigger
      self
    end

    # Конструктор, выполняет первоначальную проверку параметров
    #
    # @private
    # @param params [Hash] входящие параметры
    def initialize(params)
      @raw = params
      check
    end

    private

    # Выполняет первоначальную проверку входящих параметров
    #
    # @private
    # @raise [ActionPush::IncorrectParams] исключение с сообщением
    def check
      raise ActionPush::IncorrectParams.new('Session ID not provided') if raw[:ssid].blank?
      raise ActionPush::IncorrectParams.new('Shop ID not provided') if raw[:shop_id].blank?
      raise ActionPush::IncorrectParams.new('Action not provided') if raw[:event].blank?
      raise ActionPush::IncorrectParams.new('Unknown action') unless ActionCl::TYPES.include?(raw[:event])
      raise ActionPush::IncorrectParams.new('Incorrect item id') if raw[:event] == 'view' && (raw[:item_id].nil? || !raw[:item_id].present?)
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
      @niche_attributes = {} # Нишевые атрибуты товаров - ключ - ID товара, значение - хеш
      @action = raw[:event]
      @rating = raw[:rating].present? ? raw[:rating].to_i : nil
      @recommended_by = raw[:recommended_by]
      @order_id = raw[:order_id]
      @order_price = raw[:order_price].to_f
      @trigger_mail_code = raw[:trigger_mail_code]
      @digest_mail_code = raw[:digest_mail_code]
      @r46_returner_code = raw[:returner_code]
      @web_push_trigger_code = raw[:web_push_trigger_code]
      @web_push_digest_code = raw[:web_push_digest_code]
      @propeller_code = raw[:propeller_code]

      @source = raw[:source].present? ? JSON.parse(raw[:source]) : nil

      # Переход к нормальному трекингу источников, если пользователь изначально пришел не на товар, а на лендинг
      # http://y.mkechinov.ru/issue/REES-2919
      if @source
        case @source['from']
          when 'trigger_mail'
            @trigger_mail_code = @source['code']
          when 'digest_mail'
            @digest_mail_code = @source['code']
          when 'r46_returner'
            @r46_returner_code = @source['code']
          when 'web_push_trigger'
            @web_push_trigger_code = @source['code']
          when 'web_push_digest'
            @web_push_digest_code = @source['code']
          when 'propeller'
            @propeller_code = @source['code']
        end

        # Костыль для дайджестов MyToys
        Rollbar.info('MyToys digest', raw) if shop.id == 828 && @source['from'] == 'digest_mail'
        Rollbar.info('MyToys digest recommended_by', raw) if shop.id == 828 && raw[:recommended_by] == 'digest_mail'
      end

      # Добавляем код рекоммендера, для поиска
      if raw[:recommended_code].present?
        self.recommended_code = raw[:recommended_code]
      end

      # Формируем сегменты
      if raw[:segments].present?
        self.segments = raw[:segments].map { |s| "#{s[0]}_#{s[1]}" }
      end
    end

    # Извлекает пользователя
    #
    # @private
    def extract_user
      user_fetcher = UserFetcher.new(external_id: raw[:user_id],
                                     email: raw[:user_email],
                                     location: raw[:user_location],
                                     shop: shop,
                                     ssid: raw[:ssid])
      @user = user_fetcher.fetch
      @client = user_fetcher.client
      self.session = user_fetcher.session
    end


    # Склеивает триггерные письма MyToys до тех пор, пока они не научатся ставить наши атрибуты.
    # @private
    def track_mytoys_trigger
      return if @shop.id != 828 # Только для MyToys
      client = Client.find_by(user_id: @user.id, shop_id: @shop.id)
      if client && client.email.present?
        trigger_mail = TriggerMail.where(shop_id: @shop.id).where(client_id: client.id).where('date >= ?', 2.days.ago).first
        if trigger_mail
          @recommended_by = 'trigger_mail'
          @trigger_mail_code = trigger_mail.code
          @source = {
              'from' => 'trigger_mail',
              'code' => @trigger_mail_code
          }

          # todo хотя это в корне не правильно, нужно трекать показ товара только в триггере, а так при каждом посещении товара будет проходить клик
          if self.action == 'view' && self.items.present?

            # Подготавливаем данные для трекинга
            brand_items = self.items.select {|i| i.brand_downcase.present? }
            brand_params = OpenStruct.new({
                session: self.session,
                current_session_code: self.current_session_code,
                shop: self.shop,
                type: 'trigger_mail',
                request: self.request,
            })

            # Если есть в списке брендовые товары
            if brand_items.present?

              # Добавляем трекинг просмотра всех товаров для рекоммендреров (если это брендовые товары)
              shop.shop_inventories.recommendations.includes(:vendor_campaigns).each do
                # @type [ShopInventory] shop_inventory
                |shop_inventory|

                # Проходим по списку кампаний
                shop_inventory.vendor_campaigns.where(brand: brand_items.map(&:brand_downcase)).each do
                  # @type [VendorCampaign] vendor_campaign
                  |vendor_campaign|

                  # Добавляем 2 события. Сначала view, потом click, т.к. событие view не добавляется в триггерах
                  brand_items.each do |item|
                    if item.brand_downcase == vendor_campaign.brand.downcase
                      vendor_campaign.track_view(brand_params, item.uniqid)
                    end
                  end
                end

              end
            end
          end
        end
      end
    end


    # Нормализует входящие массивы
    #
    # @private
    def normalize_item_arrays
      [:item_id, :category, :price, :is_available, :amount, :locations, :name, :description, :url, :image_url, :brand, :categories, :priority, :attributes, :cosmetics_gender, :fashion_gender, :fashion_size,  :child_gender].each do |key|
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

        item_attributes.amount = raw[:amount][i].present? && raw[:amount][i].to_i > 1 ? raw[:amount][i].to_i : 1
        item_attributes.amount = 1000 if item_attributes.amount > 1000
        item_attributes.ignored = raw[:priority][i].present? ? raw[:priority][i] == 'ignore' : false
        item_attributes.brand = raw[:brand][i] ? StringHelper.encode_and_truncate(raw[:brand][i].mb_chars.downcase.strip) : nil

        raw_is_available =  IncomingDataTranslator.is_available?(raw[:is_available][i])
        available_present = raw[:is_available].present? && raw[:is_available][i].present?

        raw_price = nil
        raw_price = raw[:price][i] if raw[:price][i].to_i > 0

        # У товара есть YML
        if shop.has_imported_yml?
          cur_item = Slavery.on_slave { Item.find_by(shop_id: shop.id, uniqid: item_id) }
          if cur_item.present?
            # товар есть в базе
            if available_present
              item_attributes.is_available = raw_is_available
            else
              item_attributes.is_available = cur_item.is_available
            end
            item_attributes.price = raw_price if !cur_item.price && raw_price.to_i > 0

            # Добавляем размер одежды из корзины и заказа, если товар есть в YML и это одежда и пр.
            if raw[:fashion_size].present? && raw[:fashion_size][i].present?
              if cur_item.is_fashion? && cur_item.fashion_gender.present? && cur_item.fashion_wear_type.present?
                # Конвертируем размер в русский
                size_table = "SizeTables::#{ cur_item.fashion_wear_type.camelcase }".safe_constantize
                if size_table
                  table = size_table.new
                  size = Rees46ML::Size.new(value: raw[:fashion_size][i])
                  converted_size = size.ru? ? size.num : table.value(cur_item.fashion_gender, size.region, :adult, size.num)
                  if converted_size
                    niche_attributes[cur_item.id] = { fashion_size: converted_size }
                  end
                end
              end

              item_attributes.is_fashion = true if item_attributes.is_fashion.nil?
              item_attributes.fashion_gender = raw[:fashion_gender][i]
            end



          else
            item_attributes.price = raw_price if raw_price.to_i > 0
            item_attributes.is_available = raw_is_available if available_present
          end

        else

          item_attributes.is_available = raw_is_available

          item_attributes.locations = raw[:locations][i].present? ? raw[:locations][i].split(',') : []
          item_attributes.price = raw_price
          item_attributes.category_id = raw[:category][i].to_s if raw[:category][i].present?
          item_attributes.category_ids = raw[:categories][i].present? ? raw[:categories][i].split(',') : []
          item_attributes.category_ids = (item_attributes.category_ids + [item_attributes.category_id]).uniq.compact

          item_attributes.name = raw[:name][i] ? StringHelper.encode_and_truncate(raw[:name][i]) : ''

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

        # Добавляем пол косметики из автоопределялки
        if raw[:cosmetics_gender].present? && raw[:cosmetics_gender][i].present? && item_attributes.cosmetic_gender.blank?
          item_attributes.is_cosmetic = true if item_attributes.is_cosmetic.nil?
          item_attributes.cosmetic_gender = raw[:cosmetics_gender][i]
        end

        # Добавляем пол одежды из автоопределялки
        if raw[:fashion_gender].present? && raw[:fashion_gender][i].present? && item_attributes.fashion_gender.blank?
          item_attributes.is_fashion = true if item_attributes.is_fashion.nil?
          item_attributes.fashion_gender = raw[:fashion_gender][i]

          if item_attributes.is_fashion
            shop.has_products_fashion = true
            shop.atomic_save if shop.changed?
          end
        end

        # Добавляем пол ребенка из автоопределялки
        if raw[:child_gender].present? && raw[:child_gender][i].present? && item_attributes.child_gender.blank?
          item_attributes.is_child = true if item_attributes.is_child.nil?
          item_attributes.child_gender = raw[:child_gender][i]
        end

        @items << Item.fetch(shop.id, item_attributes)

      end
    rescue JSON::ParserError => e
      raise ActionPush::IncorrectParams.new(e.message)
    end

    def extract_category
      if raw[:category_id].present?
        self.category = ItemCategory.find_by(shop: self.shop, external_id: raw[:category_id])
        raise ActionPush::IncorrectParams.new('Unknown category') if self.category.nil?
      end
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
