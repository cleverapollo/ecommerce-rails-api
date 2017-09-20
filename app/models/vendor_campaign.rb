class VendorCampaign < MasterTable
  belongs_to :shop
  belongs_to :shop_inventory
  belongs_to :currency
  validates :vendor_id, :shop_id, :currency_id, presence: true, numericality: { only_integer: true }
  validates :max_cpc_price, presence: true, numericality: { greater_than: 0 }
  validates :name, presence: true

  has_attached_file :image
  validates_attachment_content_type :image, content_type: /\Aimage/
  validates_attachment_file_name :image, matches: [/png\Z/i, /jpe?g\Z/i]

  enum status: [:draft, :moderation, :published, :declined, :stopped]

end
