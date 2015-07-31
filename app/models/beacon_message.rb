##
# Сообщение от iBeacon
#
class BeaconMessage < ActiveRecord::Base

  belongs_to :shop
  belongs_to :user
  belongs_to :session

  validates :shop, presence: true
  validates :user, presence: true
  validates :session, presence: true
  validates :params, presence: true

  store :params, coder: JSON

  scope :with_notifications, -> { where(notified: true) }
end
