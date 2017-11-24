class BrandCampaignItemCategory < ActiveRecord::Base

  # Prevent from changes
  after_find :readonly!

  belongs_to :brand_campaign
  belongs_to :item_category
end
