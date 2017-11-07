class OrderItemCl < ActiveRecord::Base
  self.table_name = 'order_items'
  establish_connection "#{Rails.env}_clickhouse".to_sym

  belongs_to :shop
  belongs_to :session

  TOP_QUERY_LIST_DAYS = 30

  scope :shop, ->(shop_id) { where(shop_id: shop_id) }
  scope :created_within_days, ->(duration) { where('date >= ? AND created_at > ?', duration.days.ago.to_date, duration.days.ago) }
  scope :by_recommended_code, -> (query) { where(recommended_code: query) }
  
end
