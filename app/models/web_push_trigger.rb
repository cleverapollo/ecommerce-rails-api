class WebPushTrigger < ActiveRecord::Base

  belongs_to :shop
  validates :subject, :shop_id, :message, :trigger_type, presence: true

  scope :enabled, -> { where(enabled: true) }

end
