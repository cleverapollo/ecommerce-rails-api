class BrandCampaignShop < MasterTable

  belongs_to :brand_campaign
  belongs_to :shop
  has_many :brand_campaign_statistics_events
end
