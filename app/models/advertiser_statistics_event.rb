class AdvertiserStatisticsEvent < ActiveRecord::Base

  establish_connection MASTER_DB if !Rails.env.test?


  validates :advertiser_statistic_id, :advertiser_shop_id, :event, presence: true
  belongs_to :advertiser_statistic
  belongs_to :advertiser_shop
end
