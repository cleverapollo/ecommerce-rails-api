class WebPush::Statistics

  # @return [Shop] shop
  attr_accessor :shop

  class << self
    def recalculate_all
      Shop.connected.active.unrestricted.each do |shop|
        new(shop).recalculate
      end
      true
    end
    def recalculate_prev_all
      Shop.connected.active.unrestricted.each do |shop|
        new(shop).recalculate_prev_month
      end
      true
    end
  end

  # @param [Shop] shop
  def initialize(shop)
    self.shop = shop
  end

  # Делает расчет всех данных триггера
  def recalculate
    shop.web_push_triggers.enabled.each do
    # @type trigger [WebPushTrigger]
    |trigger|
      trigger.statistic = {} if trigger.statistic.nil?

      Slavery.on_slave do
        # Расчитываем статистику за последние 24 часа
        # дополнительный фильтры по "date" нужен для активации индекса
        trigger.statistic[:today] = {
            sent: trigger.web_push_trigger_messages.where('"date" >= ?', 1.day.ago.to_date).where(created_at: 1.day.ago..Time.now).count,
            showed: trigger.web_push_trigger_messages.where('"date" >= ?', 1.day.ago.to_date).where(created_at: 1.day.ago..Time.now).showed.count,
            clicked: trigger.web_push_trigger_messages.where('"date" >= ?', 1.day.ago.to_date).where(created_at: 1.day.ago..Time.now).clicked.count,
            purchases: trigger.with_orders_count(1.day.ago..Time.now)
        }

        # Расчитываем статистику за предыдущие 24 часа
        trigger.statistic[:yesterday] = {
            sent: trigger.web_push_trigger_messages.where('"date" >= ?', 2.day.ago.to_date).where(created_at: 2.days.ago..1.day.ago).count,
            showed: trigger.web_push_trigger_messages.where('"date" >= ?', 2.day.ago.to_date).where(created_at: 2.days.ago..1.day.ago).showed.count,
            clicked: trigger.web_push_trigger_messages.where('"date" >= ?', 2.day.ago.to_date).where(created_at: 2.days.ago..1.day.ago).clicked.count,
            purchases: trigger.with_orders_count(2.days.ago..1.day.ago)
        }

        # Расчитываем статистику за текущий месяц
        trigger.statistic[:this_month] = {
            sent: trigger.web_push_trigger_messages.this_month.count,
            showed: trigger.web_push_trigger_messages.this_month.showed.count,
            clicked: trigger.web_push_trigger_messages.this_month.clicked.count,
            unsubscribed: trigger.web_push_trigger_messages.this_month.unsubscribed.count,
            purchases: trigger.with_orders_count(Date.current.beginning_of_month..Time.current),
            purchases_value: trigger.with_orders_value(Date.current.beginning_of_month..Time.current),
        }

        # Расчитываем статистику за все время
        trigger.statistic[:all] = {
            sent: trigger.web_push_trigger_messages.count,
            showed: trigger.web_push_trigger_messages.showed.count,
            clicked: trigger.web_push_trigger_messages.clicked.count,
            unsubscribed: trigger.web_push_trigger_messages.unsubscribed.count,
            purchases: trigger.with_orders_count,
            purchases_value: trigger.with_orders_value,
        }
      end

      trigger.atomic_save! if trigger.changed?
    end
    true
  end

  # Высчитывает статистику за прошлый месяц
  def recalculate_prev_month
    shop.web_push_triggers.enabled.each do
    # @type trigger [WebPushTrigger]
    |trigger|
      trigger.statistic = {} if trigger.statistic.nil?

      Slavery.on_slave do
        # Расчитываем статистику за текущий месяц
        trigger.statistic[:previous_month] = {
            sent: trigger.web_push_trigger_messages.previous_month.count,
            showed: trigger.web_push_trigger_messages.previous_month.showed.count,
            clicked: trigger.web_push_trigger_messages.previous_month.clicked.count,
            unsubscribed: trigger.web_push_trigger_messages.previous_month.unsubscribed.count,
            purchases: trigger.with_orders_count(1.month.ago.beginning_of_month..1.month.ago.end_of_month),
            purchases_value: trigger.with_orders_value(1.month.ago.beginning_of_month..1.month.ago.end_of_month),
        }
      end

      trigger.atomic_save! if trigger.changed?
    end
  end
end
