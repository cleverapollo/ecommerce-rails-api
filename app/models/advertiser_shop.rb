class AdvertiserShop < ActiveRecord::Base
  belongs_to :advertiser
  belongs_to :shop
end
