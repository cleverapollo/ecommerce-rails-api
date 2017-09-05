class Actions::Tracker

  RATING_PURCHASE = 5
  RATING_CART = 4.2
  RATING_REMOVE = 3.7
  RATING_VIEW = 3.2

  # @return [ActionPush::Params]
  attr_accessor :params

  # @param [ActionPush::Params] params
  def initialize(params)
    self.params = params
  end

  # Трекаем действие
  def track

    # Если указаны товары, трекаем все товары
    if params.items.present?
      params.items.each do |item|
        #track_object(item.class, item.uniqid)
        save_to_mahout(item)

        # Если товар входит в список продвижения, то трекаем его событие, если это был клик или покупка
        Promoting::Brand.find_by_item(item, false).each do |brand_campaign_id|
          BrandLogger.track_click brand_campaign_id, params.shop.id, params.recommended_by
        end
      end
    end

    process
  end

  private

  # todo тестируем вставку в Clickhouse
  # @param [String] type
  # @param [String] id
  def track_object(type, id)
    begin
      thread = Thread.new do
        ActionCl.create!(
            session_id: params.session.id,
            current_session_code: params.current_session_code,
            shop_id: params.shop.id,
            event: params.action,
            object_type: type,
            object_id: id,
            recommended_by: params.recommended_by.present? ? params.recommended_by : nil,
            recommended_code: params.source.present? && params.source['code'].present? ? params.source['code'] : nil,
            referer: params.request.referer,
            useragent: params.request.user_agent,
        )
      end
      thread.join if Rails.env.test?
    rescue StandardError => e
      Rollbar.error 'Clickhouse action insert error', e
    end
  end

  # @param [Item] item
  def save_to_mahout(item)
    if params.shop.present? && params.shop.use_brb? && params.user && item && %w(cart purchase remove_from_cart).include?(params.action)
      mahout_service = MahoutService.new(params.shop.brb_address)
      mahout_service.set_preference(params.shop.id, params.user.id, item.id, rating)
    end
  end

  # Расчитывает рейтинг для события. Используется для отправки в махаут
  def rating
    case params.action
      when 'cart'
        RATING_CART
      when 'purchase'
        RATING_PURCHASE
      when 'remove_from_cart'
        RATING_REMOVE
      else
        RATING_VIEW
    end
  end

  # Выполняется по завершению
  def process
    case params.action

      when 'cart'
        process_cart

      when 'purchase'
        process_purchase

      when 'remove_from_cart'
        process_remove_from_cart

      else
        nil
    end
  end

  # Добавляем товары в корзину
  def process_cart
    ClientCart.track(params.shop, params.user, params.items, params.segments)
  end

  # Создаем заказ
  def process_purchase
    Order.persist(params)

    # Отмечаем, что юзер что-то уже купил
    params.client.bought_something = true
    params.client.supply_trigger_sent = nil
    params.client.atomic_save if params.client.changed?
    params.user.client_carts.destroy_all
  end

  # Убираем из корзины удаленные товары
  def process_remove_from_cart
    if params.items.any?
      cart = ClientCart.find_by(shop_id: params.shop.id, user_id: params.user.id)
      if cart.present?
        cart.remove_from_cart(params.items.map(&:id))
      end
    end
  end
end
