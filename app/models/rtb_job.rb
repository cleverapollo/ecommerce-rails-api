class RtbJob < MasterTable
  validates :user_id, :item_id, :shop_id, presence: true
end
