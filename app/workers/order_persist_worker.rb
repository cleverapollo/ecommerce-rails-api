class OrderPersistWorker
  include Sidekiq::Worker
  sidekiq_options retry: true, queue: 'order'

  # @return [Session]
  attr_accessor :session
  # @return [Array<Session>]
  attr_accessor :sessions
  attr_accessor :current_session_code
  # @return [User]
  attr_accessor :user
  # @return [Shop]
  attr_accessor :shop
  # @return [Order]
  attr_accessor :order
  attr_accessor :order_price

  # @param [Number] order_id
  # @param [Hash<session,order_price,source,segments,current_session_code>] params
  def perform(order_id, params = {})
    params = params.with_indifferent_access

    # Строим снова параметры
    self.order = Order.find(order_id)
    self.user = order.user
    self.session = Session.find_by_code(params[:session]) if params[:session].present?
    self.sessions = []
    self.sessions << session if session.present?
    self.sessions += user.sessions.where('updated_at >= ?', 2.days.ago.to_date).order(updated_at: :desc).limit(20)
    self.shop = order.shop
    self.order_price = params[:order_price]
    self.current_session_code = params[:current_session_code]

    # Строим источник
    source = make_source_class(params[:source])

    # Если source в параметрах нет, ищем в истории посещения
    if source.nil?
      action = ActionCl.where(shop: shop, session: sessions, event: 'view', object_type: 'Item', recommended_by: %w(trigger_mail digest_mail r46_returner web_push_digest web_push_trigger))
                       .where('date >= ? AND date <= ?', (order.date - 2.day).to_date, order.date.to_date)
                       .order(date: :desc).limit(1)
                       .select(:recommended_by, :recommended_code)[0]

      # Если нашли в истории, создаем класс источника
      source = make_source_class({ 'from' => action.recommended_by, 'code' => action.recommended_code }) if action.present?
    end

    # Если источник существует, проставляем что все товары рекомендованы нами
    if source.present?
      order.order_items.update_all(recommended_by: source.class.to_s.underscore)
    end

    # Расчитываем суммы по заказу. Если заказ из нашего канала, то все товары рекомендованные.
    values = order_values

    # Обновляем данные заказа
    order.assign_attributes(common_value: values[:common_value],
                 recommended_value: values[:recommended_value],
                 value: values[:value],
                 recommended: (values[:recommended_value] > 0),
                 ab_testing_group: Client.find_by(user_id: user.id, shop_id: shop.id).try(:ab_testing_group),
                 source: source,
                 segments: params[:segments])
    order.atomic_save if order.changed?
  ensure
    ActiveRecord::Base.clear_active_connections!
    ActiveRecord::Base.connection.close
  end

  private

  # @param [Hash] source
  # @return [TriggerMail|DigestMail|RtbImpression|WebPushDigestMessage|WebPushTriggerMessage|nil]
  def make_source_class(source)
    # Привязка заказа к письму
    if source.present? && source['from'].present?
      klass = if source['from'] == 'trigger_mail'
        TriggerMail
      elsif source['from'] == 'digest_mail'
        DigestMail
      elsif source['from'] == 'r46_returner'
        RtbImpression
      elsif source['from'] == 'web_push_digest'
        WebPushDigestMessage
      elsif source['from'] == 'web_push_trigger'
        WebPushTriggerMessage
      end

      return klass.find_by(code: source['code']) if klass.present?
    end

    nil
  end

  # Считает общую сумму заказа
  def order_values
    result = { value: 0.0, common_value: 0.0, recommended_value: 0.0 }

    # Проходим по списку созданных товаров в заказе
    order.order_items.each do |order_item|

      # Пробуем найти в истории, что товар был рекомендован (исключаем триггеры, дайджесты и т.п.)
      action = ActionCl.where(shop: shop, session: sessions, object_type: 'Item', object_id: order_item.item.uniqid)
                       .where.not(recommended_by: nil)
                       .where.not(recommended_by: %w(trigger_mail digest_mail r46_returner web_push_digest web_push_trigger))
                       .where('date >= ? AND date <= ?', (order.date - Order::RECOMMENDED_BY_DECAY).to_date, order.date.to_date)
                       .order(date: :desc).limit(1)
                       .select(:recommended_by, :recommended_code)[0]

      # Если у товара пустой рекоммендер и было рекомендованное действие
      if order_item.recommended_by.blank? && action.present? && action.recommended_by.present?
        order_item.recommended_by = action.recommended_by
        order_item.atomic_save if order_item.changed?
      end

      # Если у товара уже стоит флаг рекомендованного или он есть в истории как рекомендованный
      if order_item.recommended_by.present?
        result[:recommended_value] += (order_item.item.price.try(:to_f) || 0.0) * (order_item.amount.try(:to_f) || 1.0)
      else
        result[:common_value] += (order_item.item.price.try(:to_f) || 0.0) * (order_item.amount.try(:to_f) || 1.0)
      end

      begin
        # Если сессия была указана, значит вокрер пришел из пуша
        # Условие добавлено специально, чтобы при дебаге не трекать повторно заказ
        if session.present?

          # Если товар входит в список продвижения
          # todo перенесено из OrderItem.persist - удалить, когда будут выпилены старые бренды
          Promoting::Brand.find_by_item(order_item.item, false).each do |brand_campaign_id|

            # В ежедневную статистику
            BrandLogger.track_purchase brand_campaign_id, order.shop_id, order_item.recommended_by

            # В продажи бренда
            BrandCampaignPurchase.create! order_id: order.id, item_id: order_item.item.id, shop_id: order.shop_id, brand_campaign_id: brand_campaign_id, date: Date.current, price: (order_item.item.price || 0), recommended_by: order_item.recommended_by
          end

          # Трекаем список заказов в CL для статистики вендоров
          ClickhouseQueue.order_items({
              session_id: session.id,
              shop_id: shop.id,
              user_id: user.id,
              order_id: order.id,
              item_uniqid: order_item.item.uniqid,
              amount: order_item.amount || 1,
              price: order_item.item.price || 0,
              recommended_by: order_item.recommended_by,
              recommended_code: action.present? ? action.recommended_code : nil,
              brand: order_item.item.brand_downcase
          }, {
              current_session_code: current_session_code,
          })
        end
      rescue Exception => e
        raise e unless Rails.env.production?
        Rollbar.error 'Rabbit insert error', e
      end
    end

    # Если сумма заказа пришла в push
    if order_price.present? && order_price > 0
      result[:value] = order_price
    else
      result[:value] = result[:common_value] + result[:recommended_value]
    end

    result
  end
end
