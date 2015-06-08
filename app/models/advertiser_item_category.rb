class AdvertiserItemCategory < ActiveRecord::Base
  belongs_to :advertiser
  belongs_to :item_category
end
