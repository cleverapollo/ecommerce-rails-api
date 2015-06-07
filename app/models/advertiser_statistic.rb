class AdvertiserStatistic < ActiveRecord::Base
  validates :cost, :advertiser_id, :views, :clicks, :original_purchases, :recommended_purchases, :date, presence: true
  belongs_to :advertiser
end
