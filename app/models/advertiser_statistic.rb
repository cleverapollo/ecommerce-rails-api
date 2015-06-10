class AdvertiserStatistic < ActiveRecord::Base
  validates :cost, :advertiser_id, :views, :original_clicks, :recommended_clicks, :original_purchases, :recommended_purchases, :date, presence: true
  belongs_to :advertiser
  has_many :orders, through: :advertiser_orders
end
