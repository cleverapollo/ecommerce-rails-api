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
        trigger_mailing.statistic[:today] = {
            sent: trigger_mailing.trigger_mails.where(created_at: 1.day.ago..Time.now).count,
            opened: trigger_mailing.trigger_mails.where(created_at: 1.day.ago..Time.now).opened.count,
            clicked: trigger_mailing.trigger_mails.where(created_at: 1.day.ago..Time.now).clicked.count,
            purchases: trigger_mailing.with_orders_count(1.day.ago..Time.now)
        }

        # Расчитываем статистику за предыдущие 24 часа
        trigger_mailing.statistic[:yesterday] = {
            sent: trigger_mailing.trigger_mails.where(created_at: 2.days.ago..1.day.ago).count,
            opened: trigger_mailing.trigger_mails.where(created_at: 2.days.ago..1.day.ago).opened.count,
            clicked: trigger_mailing.trigger_mails.where(created_at: 2.days.ago..1.day.ago).clicked.count,
            purchases: trigger_mailing.with_orders_count(2.days.ago..1.day.ago)
        }
      end

      trigger_mailing.atomic_save! if trigger_mailing.changed?
    end
  end
end
