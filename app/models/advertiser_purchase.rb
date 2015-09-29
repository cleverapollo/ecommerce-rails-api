class AdvertiserPurchase < MasterTable

  belongs_to :advertiser
  belongs_to :item
  belongs_to :shop
  belongs_to :order
  validates :advertiser_id, :item_id, :shop_id, :order_id, :price, :date, presence: true
end
