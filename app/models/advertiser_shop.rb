class AdvertiserShop < ActiveRecord::Base

  establish_connection MASTER_DB

  belongs_to :advertiser
  belongs_to :shop
  has_many :advertiser_statistics_events
end
