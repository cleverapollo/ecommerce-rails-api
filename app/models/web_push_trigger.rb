class WebPushTrigger < ActiveRecord::Base

  belongs_to :shop
  has_many :web_push_trigger_messages
  validates :subject, :shop_id, :message, :trigger_type, presence: true

  scope :enabled, -> { where(enabled: true) }

end
