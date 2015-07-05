##
# Настройки рассылок.
#
class MailingsSettings < ActiveRecord::Base

  establish_connection MASTER_DB if !Rails.env.test?


  belongs_to :shop

  validates :shop, presence: true
  validates :send_from, presence: true

  def enabled?
    !shop.restricted?
  end
end
