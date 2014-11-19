class Audience < ActiveRecord::Base
  validates_presence_of :shop_id, :external_id, :email, :enabled
  serialize :custom_attributes, JSON

  belongs_to :shop
end
