##
# Триггерная рассылка. Содержит в себе шаблоны и настройки.
#
class TriggerMailing < ActiveRecord::Base

  belongs_to :shop

  scope :enabled, -> { where(enabled: true) }
end
