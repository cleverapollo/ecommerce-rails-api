##
# Категория товара.
#
class ItemCategory < ActiveRecord::Base
  belongs_to :shop

  validates :shop_id, presence: true
  validates :external_id, presence: true
end
