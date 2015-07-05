class AdvertiserShop < ActiveRecord::Base

  establish_connection MASTER_DB if !Rails.env.test?


  belongs_to :advertiser
  belongs_to :shop
  has_many :advertiser_statistics_events
end
