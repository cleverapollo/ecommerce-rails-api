class BrandCampaignPurchase < ActiveRecord::Base

  belongs_to :brand_campaign
  belongs_to :item
  belongs_to :shop
  belongs_to :order
  validates :brand_campaign_id, :item_id, :shop_id, :order_id, :price, :date, presence: true
end
