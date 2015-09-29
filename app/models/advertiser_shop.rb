class AdvertiserShop < MasterTable

  belongs_to :advertiser
  belongs_to :shop
  has_many :advertiser_statistics_events
end
