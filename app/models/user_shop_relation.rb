class UserShopRelation < ActiveRecord::Base
  belongs_to :shop
  belongs_to :user

  scope :with_email, -> { where('email IS NOT NULL') }
end
