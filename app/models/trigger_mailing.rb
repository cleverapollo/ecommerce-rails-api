##
# Триггерная рассылка. Содержит в себе шаблоны и настройки.
#
class TriggerMailing < ActiveRecord::Base

  belongs_to :shop
  has_many :trigger_mails

  scope :enabled, -> { where(enabled: true) }


  enum images_dimension: ActiveSupport::OrderedHash[{ '120x120': 0, '140x140': 1, '160x160': 2, '180x180': 3, '200x200': 4, '220x220': 5 }]

  # Проверяет, валидный ли размер картинки
  def self.valid_image_size?(size)
    images_dimensions.key?("#{size}x#{size}")
  end

end
