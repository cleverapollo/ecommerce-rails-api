class OrderPersistWorker
  include Sidekiq::Worker
  sidekiq_options retry: true, queue: 'order'

  # @return [Session]
  attr_accessor :session
  # @return [User]
  attr_accessor :user
  # @return [Shop]
  attr_accessor :shop
  # @return [Order]
  attr_accessor :order
  attr_accessor :order_price

  # @param [Number] order_id
  # @param [Hash<session,order_price,source,segments>] params
  def perform(order_id, params)
    params = params.with_indifferent_access

    # Строим снова параметры
    self.session = Session.find_by_code(params[:session])
    self.user = session.user
    self.order = Order.find(order_id)
    self.shop = order.shop
    self.order_price = params[:order_price]

    # Выходим, если у заказа есть source и он уже был сохранен
    # todo временно, когда заказы будут обрабатыватся только в воркере, удалить
    return if order.source_type.present?

    # Строим источник
    source = make_source_class(params[:source])

    # Если source в параметрах нет, ищем в истории посещения
    if source.nil?
      action = ActionCl.where(shop: shop, session: session, event: 'view', object_type: 'Item', recommended_by: %w(trigger_mail digest_mail r46_returner web_push_digest web_push_trigger))
                       .where('date >= ?', 2.days.ago.to_date)
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

      # Костыль для дайджестов MyToys
      Rollbar.info('MyToys digest', source) if shop.id == 828

      return klass.find_by(code: source['code'])
    end

    nil
  end

  # Считает общую сумму заказа
  def order_values
    result = { value: 0.0, common_value: 0.0, recommended_value: 0.0 }

    order.order_items.each do |order_item|

      # Пробуем найти в истории, что товар был рекомендован
      if order_item.recommended_by.blank?
        action = ActionCl.where(shop: shop, session: session, object_type: 'Item', object_id: order_item.item.uniqid).where.not(recommended_by: nil)
                                 .where('date >= ?', Order::RECOMMENDED_BY_DECAY.ago.to_date)
                                 .order(date: :desc).limit(1)
                                 .select(:recommended_by)[0]
        if action.present? && action.recommended_by.present?
          order_item.recommended_by = action.recommended_by
          order_item.atomic_save
        end
      end

      # Если у товара уже стоит флаг рекомендованного или он есть в истории как рекомендованный
      if order_item.recommended_by.present?
        result[:recommended_value] += (order_item.item.price.try(:to_f) || 0.0) * (order_item.amount.try(:to_f) || 1.0)
      else
        result[:common_value] += (order_item.item.price.try(:to_f) || 0.0) * (order_item.amount.try(:to_f) || 1.0)
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
