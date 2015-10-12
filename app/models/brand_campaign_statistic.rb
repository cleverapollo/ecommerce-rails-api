class BrandCampaignStatistic < MasterTable

  validates :cost, :advertiser_id, :brand_campaign_id, :views, :original_clicks, :recommended_clicks, :original_purchases, :recommended_purchases, :date, presence: true
  belongs_to :advertiser
  belongs_to :brand_campaign
  has_many :brand_campaign_statistics_events
end
