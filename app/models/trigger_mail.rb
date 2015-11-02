##
# Отправленное триггерное письмо
#
class TriggerMail < ActiveRecord::Base

  belongs_to :shop
  belongs_to :client
  belongs_to :mailing, class_name: 'TriggerMailing', foreign_key: 'trigger_mailing_id'

  validates :shop_id, presence: true
  validates :client_id, presence: true
  validates :trigger_mailing_id, presence: true
  validates :trigger_data, presence: true

  scope :clicked, -> { where(clicked: true) }

  store :trigger_data, coder: JSON

  # Отметить факт открытия письма
  def mark_as_opened!
    update_columns(opened: true) unless opened?
  end

  # Отметить факт перехода по письму (и соответственно просмотра)
  def mark_as_clicked!
    update_columns(clicked: true, opened: true) unless clicked?
  end

  def tracking_url
    Routes.track_mail_url(code: self.code, type: 'trigger', host: Rees46::HOST, shop_id: self.shop.uniqid)
  end

  def mark_as_bounced!
    update_columns(bounced: true)

    self.client.try(:purge_email!)
  end
end
