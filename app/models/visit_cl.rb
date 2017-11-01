class VisitCl < ActiveRecord::Base
  self.table_name = 'visits'
  establish_connection "#{Rails.env}_clickhouse".to_sym

  validates :shop_id, :session_id, :user_id, presence: true

  belongs_to :shop
  belongs_to :session
  belongs_to :user

end
