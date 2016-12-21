##
# Триггерная рассылка. Содержит в себе шаблоны и настройки.
#
class TriggerMailing < ActiveRecord::Base

  belongs_to :shop

  scope :enabled, -> { where(enabled: true) }


  enum images_dimension: ActiveSupport::OrderedHash[{ '120x120': 0, '140x140': 1, '160x160': 2, '180x180': 3, '200x200': 4, '220x220': 5 }]
end
