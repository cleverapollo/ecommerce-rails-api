class RtbImpression < MasterTable
  self.primary_key = 'code'
  validates :code, :bid_id, :ad_id, :price, :currency, :shop_id, :item_id, :user_id, presence: true
end
