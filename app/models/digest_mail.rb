##
# Отправленное дайджестное письмо.
#
class DigestMail < ActiveRecord::Base
  belongs_to :shops_user
  belongs_to :shop
  belongs_to :mailing, class_name: 'DigestMailing', foreign_key: 'digest_mailing_id'
  belongs_to :batch, class_name: 'DigestMailingBatch', foreign_key: 'digest_mailing_batch_id'

  validates :shop, presence: true
  validates :shops_user, presence: true
  validates :mailing, presence: true
  validates :batch, presence: true

  # Отметить факт открытия письма
  def mark_as_opened!
    update_columns(opened: true) unless opened?
  end

  # Отметить факт перехода по письму (и соответственно просмотра)
  def mark_as_clicked!
    update_columns(clicked: true, opened: true) unless clicked?
  end

  def tracking_url
    Rails.application.routes.url_helpers.track_mail_url(code: self.code || 'test', type: 'digest', host: Rees46.host)
  end

  def mark_as_bounced!
    update_columns(bounced: true)

    self.shops_user.try(:purge_email!)
  end
end
