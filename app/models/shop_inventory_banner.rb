class ShopInventoryBanner < ActiveRecord::Base
  belongs_to :shop_inventory
  validates :image, :url, presence: true

  has_attached_file :image
  validates_attachment_content_type :image, content_type: /\Aimage/
  validates_attachment_file_name :image, matches: [/png\Z/i, /jpe?g\Z/i]

  default_scope -> { order(position: :asc, id: :asc) }
end
