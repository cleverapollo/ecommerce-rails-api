class ActionCl < ActiveRecord::Base
  self.table_name = 'actions'
  establish_connection "#{Rails.env}_clickhouse".to_sym

  belongs_to :shop
  belongs_to :session

  TYPES = %w(cart category purchase rate recone_click recone_view remove_from_cart view)

  scope :in_date, ->(range) { where('date >= ? AND date <= ? AND created_at >= ? AND created_at < ?', range.first.in_time_zone('Moscow').to_date, range.last.in_time_zone('Moscow').to_date, range.first.in_time_zone('Moscow'), range.last.in_time_zone('Moscow')) }
end
