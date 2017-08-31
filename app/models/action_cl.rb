class ActionCL < ActiveRecord::Base
  self.table_name = 'actions'
  establish_connection "#{Rails.env}_clickhouse".to_sym
end
