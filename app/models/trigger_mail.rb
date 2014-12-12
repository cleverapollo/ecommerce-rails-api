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

  # Отметить факт открытия письма
  def mark_as_opened!
    update_columns(opened: true) unless opened?
  end

  # Отметить факт перехода по письму (и соответственно просмотра)
  def mark_as_clicked!
    update_columns(clicked: true, opened: true) unless clicked?
  end

  def tracking_url
    Rails.application.routes.url_helpers.track_mail_url(code: self.code, type: 'trigger', host: Rees46.host)
  end
end
