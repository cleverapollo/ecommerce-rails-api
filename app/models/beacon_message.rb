##
# Сообщение от iBeacon
#
class BeaconMessage < ActiveRecord::Base

  belongs_to :shop
  belongs_to :user
  belongs_to :session
  belongs_to :beacon_offer


  validates :shop_id, presence: true
  validates :user_id, presence: true
  validates :session_id, presence: true
  validates :params, presence: true
  validates :beacon_offer_id, presence: true

  store :params, coder: JSON

  scope :with_notifications, -> { where(notified: true) }
end
