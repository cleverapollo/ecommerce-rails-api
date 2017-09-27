class InteractionCl < ActiveRecord::Base
  self.table_name = 'interactions'
  establish_connection "#{Rails.env}_clickhouse".to_sym
end
