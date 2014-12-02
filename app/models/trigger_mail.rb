##
# Отправленное триггерное письмо
#
class TriggerMail < ActiveRecord::Base
  belongs_to :shop
  belongs_to :subscription

  validates :shop, presence: true
  validates :subscription, presence: true
  validates :trigger_code, presence: true, inclusion: { in: TriggerMailings::Triggers::NAMES }
  validates :trigger_data, presence: true

  store :trigger_data, coder: JSON

  def open!
    update_columns(opened: true) unless opened?
  end
end
