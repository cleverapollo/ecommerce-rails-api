##
# Отправленное дайджестное письмо.
#
class DigestMail < ActiveRecord::Base

  belongs_to :client
  belongs_to :shop
  belongs_to :mailing, class_name: 'DigestMailing', foreign_key: 'digest_mailing_id'
  belongs_to :batch, class_name: 'DigestMailingBatch', foreign_key: 'digest_mailing_batch_id'

  validates :shop, presence: true
  validates :client, presence: true
  validates :mailing, presence: true
  validates :batch, presence: true

  before_create :set_date

  scope :clicked, -> { where(clicked: true) }
  scope :opened, -> { where(opened: true) }
  scope :bounced, -> { where(bounced: true) }

  # Отметить факт открытия письма
  def mark_as_opened!
    unless opened?
      update_columns(opened: true)

      # Отмечаем, что клиент хоть раз открывал дайджестную рассылку.
      # Используется в динамическом сегментаторе
      client.update_columns(digest_opened: true) unless client.digest_opened?
    end
  end

  # Отметить факт перехода по письму (и соответственно просмотра)
  def mark_as_clicked!
    update_columns(clicked: true, opened: true) unless clicked?
    self
  end

  def tracking_url
    Routes.track_mail_url(code: code || 'test', type: 'digest', host: Rees46::HOST, shop_id: shop.uniqid)
  end

  def mark_as_bounced!
    update_columns(bounced: true)

    self.client.try(:purge_email!)
  end


  private

  def set_date
    Time.use_zone(shop.customer.time_zone) do
      self.date = Date.current
    end
  end

end
