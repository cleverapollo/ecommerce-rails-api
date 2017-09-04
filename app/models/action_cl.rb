class ActionCl < ActiveRecord::Base
  self.table_name = 'actions'
  establish_connection "#{Rails.env}_clickhouse".to_sym

  belongs_to :shop
  belongs_to :session
end
