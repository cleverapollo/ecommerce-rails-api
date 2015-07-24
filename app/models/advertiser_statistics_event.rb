class AdvertiserStatisticsEvent < ActiveRecord::Base

  establish_connection MASTER_DB


  validates :advertiser_statistic_id, :advertiser_shop_id, :event, presence: true
  belongs_to :advertiser_statistic
  belongs_to :advertiser_shop
end
