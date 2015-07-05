class AdvertiserItemCategory < ActiveRecord::Base

  establish_connection MASTER_DB if !Rails.env.test?


  belongs_to :advertiser
  belongs_to :item_category
end
