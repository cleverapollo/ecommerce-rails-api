class RtbImpression < MasterTable
  validates :code, :bid_id, :ad_id, :price, :currency, :shop_id, :item_id, :user_id, presence: true
end
