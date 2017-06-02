class BrandCampaignStatistic < ActiveRecord::Base

  validates :cost, :brand_campaign_id, :views, :original_clicks, :recommended_clicks, :original_purchases, :recommended_purchases, :date, presence: true
  belongs_to :brand_campaign
  has_many :brand_campaign_statistics_events
end
