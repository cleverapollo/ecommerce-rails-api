class WebPushTrigger < ActiveRecord::Base

  belongs_to :shop

  scope :enabled, -> { where(enabled: true) }

end
