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

      # Иногда событие заказа приходит несколько раз
      return nil if uniqid.present? && duplicate?(shop, user, uniqid, items)

      # Иногда заказы бывают без ID
      uniqid = generate_uniqid(shop.id) if uniqid.blank?

      # Используем вставку UPSET для предотвращения конфиктов уникальных значений
      Order.connection.insert(ActiveRecord::Base.send(:sanitize_sql_array, [
          'INSERT INTO orders (shop_id, uniqid, user_id, "date") VALUES(?, ?, ?, ?) ON CONFLICT (shop_id, uniqid) DO NOTHING', shop.id, uniqid, user.id, Time.now
      ]))
      order = Order.find_by shop_id: shop.id, uniqid: uniqid

      # Выходим, если заказ было создан не сегодня
      return nil if order.date.to_date < Date.current

      # Если получили список товаров и у заказа товары уже есть, значит заказ старый, можно удалить товары
      if items.size > 0 && order.order_items.count > 0
        order.order_items.delete_all
      end

      # Сохраняем позиции заказа
      items.each do |item|
        OrderItem.atomic_create!(order_id: order.id, item_id: item.id, shop_id: shop.id, amount: item.amount)
      end

      # Отправляем в работу для пересчета рекомендаций
      OrderPersistWorker.perform_async(order.id, { session: params.session.code, current_session_code: params.current_session_code, order_price: params.order_price, source: params.source, segments: params.segments })

      order
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
