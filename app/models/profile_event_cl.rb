class ProfileEventCl < ActiveRecord::Base
  self.table_name = 'profile_events'
  establish_connection "#{Rails.env}_clickhouse".to_sym

  belongs_to :shop
  belongs_to :session
end
