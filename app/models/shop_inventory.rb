class ShopInventory < MasterTable
  belongs_to :shop
  belongs_to :currency
  has_many :shop_inventory_banners
  has_many :vendor_campaigns
  validates :min_cpc_price, :currency_id, :shop_id, :inventory_type, :name, presence: true
  validates :min_cpc_price, numericality: { greater_than: 0 }

  TYPES = [:banner, :sponsored, :recommendations, :popup]
  enum inventory_type: TYPES

  scope :active, -> { where(active: true) }
  scope :recommendations, -> { where(inventory_type: TYPES.index(:recommendations)) }

  default_scope -> { active }
end
