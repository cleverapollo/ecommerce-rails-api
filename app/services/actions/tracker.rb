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
        track_object(item.class, item.uniqid)
        save_to_mahout(item)

        # Если товар входит в список продвижения, то трекаем его событие, если это был клик или покупка
        Promoting::Brand.find_by_item(item, false).each do |brand_campaign_id|
          BrandLogger.track_click brand_campaign_id, params.shop.id, params.recommended_by
        end
      end
    end

    # Трекаем просмотр категории
    if params.action == 'category' && params.category.present?
      track_object(params.category.class, params.category.external_id)
    end

    if %w(recone_view recone_click).include?(params.action)
      if params.raw['campaign'].present?
        track_object(VendorCampaign, params.raw['campaign'])
      else
        track_object(ShopInventoryBanner, params.raw['inventory'])
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
    order = Order.persist(params)

    # Если заказ не был создан, нечего и трекать
    return nil if order.nil?

    # Отмечаем, что юзер что-то уже купил
    params.client.bought_something = true
    params.client.supply_trigger_sent = nil
    params.client.atomic_save if params.client.changed?
    params.user.client_carts.destroy_all

    params.items.each do |item|
      begin
        ClickhouseQueue.order_items({
            session_id: params.session.id,
            shop_id: params.shop.id,
            user_id: params.user.id,
            order_id: order.id,
            item_uniqid: item.uniqid,
            amount: item.amount,
            price: item.price.to_f,
            recommended_by: order.order_items.find_by(item_id: item.id).try(:recommended_by),
            brand: item.brand_downcase
        })
      rescue Exception => e
        raise e unless Rails.env.production?
        Rollbar.error 'Rabbit insert error', e
      end
    end

    # # Трекаем заказы товаров в ClickHouse
    # thread = Thread.new do
    #   params.items.each do |item|
    #     begin
    #
    #       # todo говнокод для теста (справится ли кликхаус)
    #       connection = Net::HTTP.start('144.76.156.6', '8123')
    #       sql = "INSERT INTO order_items (session_id, shop_id, order_id, item_uniqid, amount, price, recommended_by, brand) VALUES(#{params.session.id}, #{params.shop.id}, #{order.id}, '#{item.uniqid}', #{item.amount}, #{item.price}, '#{order.order_items.find_by(item_id: item.id).try(:recommended_by)}', '#{item.brand_downcase}')"
    #       res = connection.post('/?database=rees46', sql)
    #       raise res.code if res.code.to_i != 200
    #
    #
    #       # OrderItemCl.create!(
    #       #     session_id: params.session.id,
    #       #     shop_id: params.shop.id,
    #       #     order_id: order.id,
    #       #     item_uniqid: item.uniqid,
    #       #     amount: item.amount,
    #       #     price: item.price,
    #       #     recommended_by: order.order_items.find_by(item_id: item.id).try(:recommended_by),
    #       #     brand: item.brand_downcase
    #       # )
    #     rescue StandardError => e
    #       Rollbar.error 'Clickhouse order_items insert error', e
    #     end
    #   end
    #
    #   # Смотрим есть ли в товарах вообще бренды
    #   if params.items.map(&:brand).reject { |c| c.blank? }.present?
    #     begin
    #       # пробуем найти события кликов по кампании вендора за 2 последних дня
    #       campaign_ids = ActionCl.where(
    #           session_id: params.session.id,
    #           current_session_code: params.current_session_code,
    #           shop_id: params.shop.id,
    #           event: 'recone_click',
    #           object_type: VendorCampaign,
    #       ).where('date >= ?', 2.days.ago.to_date).pluck(:object_id)
    #
    #       # если нашлось
    #       if campaign_ids.present?
    #         campaigns = VendorCampaign.where(id: campaign_ids)
    #         campaigns.each do |campaign|
    #           params.items.each do |item|
    #             # Если бренды совпдают
    #             if item.brand_downcase == campaign.brand.downcase
    #               # трекаем событие покупки
    #               ActionCl.create!(
    #                   session_id: params.session.id,
    #                   current_session_code: params.current_session_code,
    #                   shop_id: params.shop.id,
    #                   event: 'recone_purchase',
    #                   object_type: VendorCampaign,
    #                   object_id: campaign.id,
    #                   recommended_by: nil,
    #                   recommended_code: item.price.to_f.to_s,
    #                   referer: params.request.referer,
    #                   useragent: params.request.user_agent,
    #               )
    #             end
    #           end
    #         end
    #       end
    #     rescue StandardError => e
    #       Rollbar.error 'Clickhouse action insert error', e
    #     end
    #   end
    # end
    # thread.join unless Rails.env.production?
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
