class BrandCampaignItemCategory < MasterTable

  # Prevent from changes
  after_find :protect_it

  belongs_to :brand_campaign
  belongs_to :item_category
end
