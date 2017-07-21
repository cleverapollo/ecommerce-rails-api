##
# Дайджестная рассылка.
#
class DigestMailing < ActiveRecord::Base

  class DisabledError < StandardError; end

  serialize :statistic, HashSerializer

  enum images_dimension: ActiveSupport::OrderedHash[{ '120x120': 0, '140x140': 1, '160x160': 2, '180x180': 3, '200x200': 4, '220x220': 5 }]

  include Redis::Objects
  counter :sent_mails_count
  belongs_to :shop
  belongs_to :segment

  has_many :mails, class_name: 'DigestMail'
  has_many :batches, class_name: 'DigestMailingBatch'

  scope :finished, -> { where(state: 'finished') }

  # Отметить рассылку как прерванную.
  def fail!
    update(state: 'failed')
  end

  def failed?
    self.state == 'failed' || self.state == 'spam'
  end

  def started?
    self.state == 'started'
  end

  def finish!
    update(state: 'finished', finished_at: Time.current)
  end

  # Возобновить сломавшуюся рассылку
  def resume!
    if self.state == 'failed'
      update(state: 'started')
      batches.incomplete.each{|batch| DigestMailingBatchWorker.perform_async(batch.id) }
    end
  end

  def mailchimp_attr_present?
    self.mailchimp_campaign_id.present? && self.mailchimp_list_id.present?
  end

  # Проверяет, валидный ли размер картинки
  def self.valid_image_size?(size)
    images_dimensions.key?("#{size}x#{size}")
  end

  def statistic
    if super.present?
      super
    else
      {sent: 0, opened: 0, clicked: 0, bounced: 0, unsubscribed: 0, purchases: 0, revenue: 0}
    end
  end

  # Запускает перерасчет статистики дайджеста
  def recalculate_statistic
    Slavery.on_slave do
      self.statistic = {
          sent: self.mails.count,
          opened: self.mails.opened.count,
          clicked: self.mails.clicked.count,
          bounced: self.mails.bounced.count,
          unsubscribed: 0,
          purchases: self.with_orders_count,
          revenue: self.with_orders_value,
      }
    end

    self.atomic_save! if self.changed?
  end

  def with_orders_count
    Order.joins('INNER JOIN digest_mails on orders.source_id = digest_mails.id').where('orders.source_type = ?', 'DigestMail').where('digest_mails.digest_mailing_id = ?', self.id).count
  end

  def with_orders_value
    Order.joins('INNER JOIN digest_mails on orders.source_id = digest_mails.id').where('orders.source_type = ?', 'DigestMail').where('digest_mails.digest_mailing_id = ?', self.id).sum(:value)
  end

end
