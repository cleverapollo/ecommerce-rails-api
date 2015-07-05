##
# Триггерная рассылка. Содержит в себе шаблоны и настройки.
#
class TriggerMailing < ActiveRecord::Base

  establish_connection MASTER_DB if !Rails.env.test?


  belongs_to :shop

  scope :enabled, -> { where(enabled: true) }
end
