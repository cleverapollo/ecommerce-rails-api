class OrderItemCl < ActiveRecord::Base
  self.table_name = 'order_items'
  establish_connection "#{Rails.env}_clickhouse".to_sym

  belongs_to :shop
  belongs_to :session
end
