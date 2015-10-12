class BrandCampaignItemCategory < MasterTable

  belongs_to :advertiser
  belongs_to :brand_campaign
  belongs_to :item_category
end
