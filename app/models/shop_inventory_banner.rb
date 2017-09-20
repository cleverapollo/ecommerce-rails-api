class ShopInventoryBanner < MasterTable
  belongs_to :shop_inventory
  validates :image, :url, presence: true

  has_attached_file :image
  validates_attachment_content_type :image, content_type: /\Aimage/
  validates_attachment_file_name :image, matches: [/png\Z/i, /jpe?g\Z/i]

end
