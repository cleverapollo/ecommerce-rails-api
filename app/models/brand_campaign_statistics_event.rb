class BrandCampaignStatisticsEvent < MasterTable

  validates :brand_campaign_statistic_id, :brand_campaign_shop_id, :event, presence: true
  belongs_to :brand_campaign_statistic
  belongs_to :brand_campaign_shop
  belongs_to :brand_campaign
end
