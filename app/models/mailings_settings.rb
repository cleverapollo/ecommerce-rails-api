##
# Настройки рассылок.
#
class MailingsSettings < ActiveRecord::Base
  belongs_to :shop

  validates :shop, presence: true
  validates :send_from, presence: true

  def enabled?
    !shop.restricted?
  end
end
