##
# Отправленное дайджестное письмо.
#
class DigestMail < ActiveRecord::Base

  belongs_to :client
  belongs_to :shop_email
  belongs_to :shop
  belongs_to :mailing, class_name: 'DigestMailing', foreign_key: 'digest_mailing_id'
  belongs_to :batch, class_name: 'DigestMailingBatch', foreign_key: 'digest_mailing_batch_id'

  validates :shop, presence: true
  validates :mailing, presence: true
  validates :batch, presence: true

  before_create :set_date

  scope :clicked, -> { where(clicked: true) }
  scope :opened, -> { where(opened: true) }
  scope :bounced, -> { where(bounced: true) }
  scope :unsubscribed, -> { where(unsubscribed: true) }

  BOUNCE_UNSUBSCRIBED = 1
  BOUNCE_ABUSE = 2
  BOUNCE_MAILING_SYSTEM = 3

  # Отметить факт открытия письма
  def mark_as_opened!
    unless opened?
      update_columns(opened: true)

      # Отмечаем, что клиент хоть раз открывал дайджестную рассылку.
      # Используется в динамическом сегментаторе
      shop_email.update_columns(digest_opened: true) if shop_email_id.present? && !shop_email.digest_opened?
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

  # @param reason [Integer] Reason of bounce, one of ::BOUNCE_MAILING_SYSTEM, ::BOUNCE_ABUSE, ::BOUNCE_UNSUBSCRIBED
  def mark_as_bounced!(reason = nil)
    update_columns(bounced: true, bounce_reason: reason)

    self.client.shop_email.try(:purge_email!) if client_id.present? && client.present?
    self.shop_email.try(:purge_email!) if shop_email_id.present?
  end


  private

  def set_date
    Time.use_zone(shop.customer.time_zone) do
      self.date = Date.current
    end
  end

end
