class ShopInventory < MasterTable
  belongs_to :shop
  belongs_to :currency
  has_many :shop_inventory_banners
  has_many :vendor_campaigns
  validates :min_cpc_price, :currency_id, :shop_id, :inventory_type, :name, presence: true
  validates :min_cpc_price, numericality: { greater_than: 0 }

  TYPES = [:banner, :sponsored, :recommendations, :popup]
  enum inventory_type: TYPES

  PAYMENT_TYPES = { cpc: 0, cpm: 1 }
  enum payment_type: PAYMENT_TYPES

  scope :active, -> { where(active: true) }
  scope :recommendations, -> { where(inventory_type: TYPES.index(:recommendations)) }

  serialize :settings, HashSerializer

  default_scope -> { active }
end
