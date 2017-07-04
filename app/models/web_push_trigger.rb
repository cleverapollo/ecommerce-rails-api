class WebPushTrigger < ActiveRecord::Base

  belongs_to :shop
  has_many :web_push_trigger_messages
  validates :subject, :shop_id, :message, :trigger_type, presence: true

  serialize :statistic, HashSerializer

  scope :enabled, -> { where(enabled: true) }

  def with_orders_count(date_range = nil)
    relation = Order.joins('INNER JOIN web_push_trigger_messages on orders.source_id = web_push_trigger_messages.id').where('orders.source_type = ?', 'WebPushTriggerMessage').where('web_push_trigger_messages.web_push_trigger_id = ?', self.id)
    if date_range.present?
      relation = relation.where('orders.date >= ?', date_range.begin).where('web_push_trigger_messages.created_at >= ?', date_range.begin).where('web_push_trigger_messages.created_at <= ?', date_range.end)
    end
    relation.count
  end

  def with_orders_value(date_range = nil)
    relation = Order.joins('INNER JOIN web_push_trigger_messages on orders.source_id = web_push_trigger_messages.id').where('orders.source_type = ?', 'WebPushTriggerMessage').where('web_push_trigger_messages.web_push_trigger_id = ?', self.id)
    if date_range.present?
      relation = relation.where('orders.date >= ?', date_range.begin).where('web_push_trigger_messages.created_at >= ?', date_range.begin).where('web_push_trigger_messages.created_at <= ?', date_range.end)
    end
    relation.sum(:value).to_f
  end


end
