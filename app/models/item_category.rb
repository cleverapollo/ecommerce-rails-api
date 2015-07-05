##
# Категория товара.
#
class ItemCategory < ActiveRecord::Base

  establish_connection MASTER_DB if !Rails.env.test?


  belongs_to :shop

  validates :shop_id, presence: true
  validates :external_id, presence: true

  has_many :advertiser_item_categories
  has_many :item_categories, through: :advertiser_item_categories

end
