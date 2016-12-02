class RtbJob < MasterTable
  validates :user_id, :item_id, :shop_id, presence: true
  belongs_to :user
  belongs_to :item
  belongs_to :shop
  has_many :rtb_impressions, foreign_key: :ad_id
  scope :active, -> { where('active IS TRUE') }
end
