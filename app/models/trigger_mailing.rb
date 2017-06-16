##
# Триггерная рассылка. Содержит в себе шаблоны и настройки.
#
class TriggerMailing < ActiveRecord::Base

  belongs_to :shop
  has_many :trigger_mails

  scope :enabled, -> { where(enabled: true) }

  serialize :statistic, HashSerializer

  enum images_dimension: ActiveSupport::OrderedHash[{ '120x120': 0, '140x140': 1, '160x160': 2, '180x180': 3, '200x200': 4, '220x220': 5 }]

  # Проверяет, валидный ли размер картинки
  def self.valid_image_size?(size)
    images_dimensions.key?("#{size}x#{size}")
  end

  def with_orders_count(date_range = nil)
    relation = Order.joins('INNER JOIN trigger_mails ON orders.source_id = trigger_mails.id').where('orders.source_type = ?', 'TriggerMail').where('trigger_mails.trigger_mailing_id = ?', self.id)
    if date_range.present?
      relation = relation.where('trigger_mails.created_at >= ?', date_range.begin).where('trigger_mails.created_at <= ?', date_range.end)
    end
    relation.count
  end

  def with_orders_value(date_range = nil)
    relation = Order.joins('INNER JOIN trigger_mails ON orders.source_id = trigger_mails.id').where('orders.source_type = ?', 'TriggerMail').where('trigger_mails.trigger_mailing_id = ?', self.id)
    if date_range.nil?
      relation = relation.where('trigger_mails.created_at >= ?', date_range.begin).where('trigger_mails.created_at <= ?', date_range.end)
    end
    relation.sum(:value)
  end

end
