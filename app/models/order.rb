##
# Заказ
#
class Order < ActiveRecord::Base

  RECOMMENDED_BY_DECAY = 2.weeks

  include UserLinkable

  has_many :order_items, dependent: :destroy
  has_many :brand_campaign_purchases
  has_one :reputation, as: :entity
  belongs_to :source, polymorphic: true
  belongs_to :shop

  before_create :record_date
  after_create :set_reputation_key


  scope :successful, -> { where(status: self::STATUS_SUCCESS) }

  STATUS_NEW = 0
  STATUS_SUCCESS = 1
  STATUS_CANCELLED = 2

  class << self
    # Сохранить заказ
    # @param [ActionPush::Params] params
    # @return [Order]
    def persist(params)
      shop = params.shop
      user = params.user
      uniqid = params.order_id
      items = params.items
      source = params.source
      order_price = params.order_price
      segments = params.segments

      # Иногда событие заказа приходит несколько раз
      return nil if duplicate?(shop, user, uniqid, items)

      # Иногда заказы бывают без ID
      uniqid = generate_uniqid(shop.id) if uniqid.blank?

      # Используем вставку UPSET для предотвращения конфиктов уникальных значений
      Order.connection.insert(ActiveRecord::Base.send(:sanitize_sql_array, [
          'INSERT INTO orders (shop_id, uniqid, user_id, "date") VALUES(?, ?, ?, ?) ON CONFLICT (shop_id, uniqid) DO NOTHING', shop.id, uniqid, user.id, Time.now
      ]))
      order = Order.find_by shop_id: shop.id, uniqid: uniqid

      # Выходим, если заказ было создан не сегодня
      return nil if order.date.to_date < Date.current

      # Если источник пустой, пробудем найти в Clickhouse
      # if source.blank? || source['from'].blank?
      #   relation = ActionCl.where(shop_id: shop.id,
      #                              session_id: params.session.id,
      #                              event: 'view',
      #                              object_type: 'Item',
      #                              object_id: items.map { |i| i.uniqid }
      #   )
      #
      #   # Ищем для CPA
      #   action_cl = relation.where(recommended_by: %w(trigger_mail digest_mail r46_returner web_push_digest web_push_trigger)).where('date >= ?', 2.days.ago.to_date).limit(1).first
      #   if action_cl.present?
      #     source = { 'from' => action_cl.recommended_by, 'code' => action_cl.recommended_code }
      #   end
      # end

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

        source = klass.find_by(code: source['code'])
      else
        source = nil
      end

      # Расчитываем суммы по заказу. Если заказ из нашего канала, то все товары рекомендованные.
      values = order_values(shop, user, params.session, items, source.present?, order_price)

      # Обновляем данные заказа
      order.assign_attributes(common_value: values[:common_value],
                   recommended_value: values[:recommended_value],
                   value: values[:value],
                   recommended: (values[:recommended_value] > 0),
                   ab_testing_group: Client.where(user_id: user.id, shop_id: shop.id).limit(1)[0].try(:ab_testing_group),
                   source: source,
                   segments: segments)
      order.atomic_save if order.changed?

      # Если получили список товаров и у заказа товары уже есть, значит заказ старый, можно удалить товары
      if items.size > 0 && order.order_items.count > 0
        order.order_items.destroy_all
      end

      # Сохраняем позиции заказа
      items.each do |item|
        recommended_by_expicit = source.present? ? source.class.to_s.underscore : nil
        OrderItem.persist(order, item, item.amount, params, recommended_by_expicit)
      end

      order
    end

    # Расчет сумм по заказу
    def order_values(shop, user, session, items, force_recommended = false, remote_order_price = nil)
      result = { value: 0.0, common_value: 0.0, recommended_value: 0.0 }

      items.each do |item|
        if force_recommended ||
           #ActionCl.where(shop: shop, session: session).where.not(recommended_by: nil).where('date >= ?', RECOMMENDED_BY_DECAY.ago.to_date).exists? ||
           # todo выпилить, когда перейдем окончательно на кликхаус
           Slavery.on_slave { shop.actions.where(item_id: item.id, user_id: user.id).where('recommended_by is not null').where('recommended_at >= ?', RECOMMENDED_BY_DECAY.ago).exists? }
          result[:recommended_value] += (item.price.try(:to_f) || 0.0) * (item.amount.try(:to_f) || 1.0)
        else
          result[:common_value] += (item.price.try(:to_f) || 0.0) * (item.amount.try(:to_f) || 1.0)
        end
      end

      if remote_order_price && remote_order_price > 0
        result[:value] = remote_order_price
      else
        result[:value] = result[:common_value] + result[:recommended_value]
      end

      result
    end

    def duplicate?(shop, user, uniqid, items)
      if uniqid.present?
        # Добавили разницу в 1 месяц для предотвращения пропажи заказов, когда магазин сбросил uniqid
        Order.where(uniqid: uniqid, shop_id: shop.id).where('date > ?', 1.month.ago).exists?
      else
        Order.where(shop_id: shop.id, user_id: user.id)
             .where("date > ?", 1.minutes.ago).exists?
      end
    end

    def generate_uniqid(shop_id)
      loop do
        uuid = SecureRandom.uuid
        return uuid if Order.where(uniqid: uuid).where(shop_id: shop_id).none?
      end
    end
  end

  # Удаляет все товары из корзины для текущего пользователя и магазина
  # @deprecated
  # todo it used anywhere?
  def expire_carts
    user.actions.where(shop: shop).where('rating::numeric = ?', Actions::Cart::RATING).update_all(rating: Actions::RemoveFromCart::RATING)
  end


  # Изменить статус заказа, если статус валиден и изменился
  def change_status(new_status)
    if [STATUS_NEW, STATUS_CANCELLED, STATUS_SUCCESS].include?(new_status) && status != new_status
      update status: new_status, status_date: Date.current
    end
  end

  # Если
  # - уже не отменен
  # - не старше 1 месяца (TODO: фактически проверять, есть ли инвойс CPA на дату заказа)
  # - не сегодняшний (чтобы CPA инвойс уже был сформирован и комиссия снята)
  # - не компенсирован
  def refundable?
    status != STATUS_CANCELLED && date >= 1.month.ago && date.beginning_of_day < DateTime.current.beginning_of_day && compensated != true
  end

  protected

  # Устанавливаем перед созданием заказа текущую дату заказа
  def record_date
    self.date = read_attribute(:date) || Time.now
  end

  def set_reputation_key
    self.update_column(:reputation_key, Digest::MD5.hexdigest(self.id.to_s))
  end

end
