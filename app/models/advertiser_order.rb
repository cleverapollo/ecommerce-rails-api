class AdvertiserOrder < ActiveRecord::Base
  belongs_to :advertiser_statistic
  belongs_to :order
end
