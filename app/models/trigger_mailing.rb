class TriggerMailing < ActiveRecord::Base
  belongs_to :shop

  store :trigger_settings, coder: JSON
  store :mailing_settings, coder: JSON
end
