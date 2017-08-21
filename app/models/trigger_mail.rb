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

  before_create :set_date

  scope :clicked, -> { where(clicked: true) }
  scope :opened, -> { where(opened: true) }
  scope :bounced, -> { where(bounced: true) }
  scope :unsubscribed, -> { where(unsubscribed: true) }
  scope :previous_month, -> { where(date: 1.month.ago.beginning_of_month.to_date..1.month.ago.end_of_month.to_date) }
  scope :this_month, -> { where(date: Date.current.beginning_of_month..Date.current) }

  store :trigger_data, coder: JSON

  BOUNCE_UNSUBSCRIBED = 1
  BOUNCE_ABUSE = 2
  BOUNCE_MAILING_SYSTEM = 3


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

  # @param reason [Integer] Reason of bounce, one of ::BOUNCE_MAILING_SYSTEM, ::BOUNCE_ABUSE, ::BOUNCE_UNSUBSCRIBED
  def mark_as_bounced!(reason = nil)
    update_columns(bounced: true, bounce_reason: reason)

    self.client.try(:purge_email!)
  end

  private

  def set_date
    Time.use_zone(shop.customer.time_zone) do
      self.date = Date.current if self.date.blank?
    end
  end


end
