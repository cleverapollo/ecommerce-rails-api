class BeaconOffer < ActiveRecord::Base

  establish_connection MASTER_DB

  belongs_to :shop
  has_many :beacon_messages

  validates :uuid, :major, :image_url, :title, :description, :notification, :enabled, :shop_id, presence: true

  scope :active, -> { where(enabled: true) }

end