class TriggerMailings::Statistics

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
    shop.trigger_mailings.enabled.each do
    # @type trigger_mailing [TriggerMailing]
    |trigger_mailing|
      trigger_mailing.statistic = {} if trigger_mailing.statistic.nil?

      Slavery.on_slave do
        # Расчитываем статистику за последние 24 часа
        # дополнительный фильтры по "date" нужен для активации индекса
        trigger_mailing.statistic[:today] = {
            sent: trigger_mailing.trigger_mails.where('"date" >= ?', 1.day.ago.to_date).where(created_at: 1.day.ago..Time.now).count,
            opened: trigger_mailing.trigger_mails.where('"date" >= ?', 1.day.ago.to_date).where(created_at: 1.day.ago..Time.now).opened.count,
            clicked: trigger_mailing.trigger_mails.where('"date" >= ?', 1.day.ago.to_date).where(created_at: 1.day.ago..Time.now).clicked.count,
            purchases: trigger_mailing.with_orders_count(1.day.ago..Time.now)
        }

        # Расчитываем статистику за предыдущие 24 часа
        trigger_mailing.statistic[:yesterday] = {
            sent: trigger_mailing.trigger_mails.where('"date" >= ?', 2.day.ago.to_date).where(created_at: 2.days.ago..1.day.ago).count,
            opened: trigger_mailing.trigger_mails.where('"date" >= ?', 2.day.ago.to_date).where(created_at: 2.days.ago..1.day.ago).opened.count,
            clicked: trigger_mailing.trigger_mails.where('"date" >= ?', 2.day.ago.to_date).where(created_at: 2.days.ago..1.day.ago).clicked.count,
            purchases: trigger_mailing.with_orders_count(2.days.ago..1.day.ago)
        }

        # Расчитываем статистику за текущий месяц
        trigger_mailing.statistic[:this_month] = {
            sent: trigger_mailing.trigger_mails.this_month.count,
            opened: trigger_mailing.trigger_mails.this_month.opened.count,
            clicked: trigger_mailing.trigger_mails.this_month.clicked.count,
            purchases: trigger_mailing.with_orders_count(Date.current.beginning_of_month..Time.current),
            purchases_value: trigger_mailing.with_orders_value(Date.current.beginning_of_month..Time.current),
        }

        # Расчитываем статистику за все время
        trigger_mailing.statistic[:all] = {
            sent: trigger_mailing.trigger_mails.count,
            opened: trigger_mailing.trigger_mails.opened.count,
            clicked: trigger_mailing.trigger_mails.clicked.count,
            purchases: trigger_mailing.with_orders_count,
            purchases_value: trigger_mailing.with_orders_value,
        }
      end

      trigger_mailing.atomic_save! if trigger_mailing.changed?
    end
    true
  end

  # Высчитывает статистику за прошлый месяц
  def recalculate_prev_month
    shop.trigger_mailings.enabled.each do
    # @type trigger_mailing [TriggerMailing]
    |trigger_mailing|
      trigger_mailing.statistic = {} if trigger_mailing.statistic.nil?

      Slavery.on_slave do
        # Расчитываем статистику за текущий месяц
        trigger_mailing.statistic[:previous_month] = {
            sent: trigger_mailing.trigger_mails.previous_month.count,
            opened: trigger_mailing.trigger_mails.previous_month.opened.count,
            clicked: trigger_mailing.trigger_mails.previous_month.clicked.count,
            purchases: trigger_mailing.with_orders_count(1.month.ago.beginning_of_month..1.month.ago.end_of_month),
            purchases_value: trigger_mailing.with_orders_value(1.month.ago.beginning_of_month..1.month.ago.end_of_month),
        }
      end

      trigger_mailing.atomic_save! if trigger_mailing.changed?
    end
  end
end
