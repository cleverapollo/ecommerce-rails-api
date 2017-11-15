##
# Часть дайджестной рассылки.
#
class DigestMailingBatch < ActiveRecord::Base

  include Redis::Objects
  value :current_processed_client_id

  belongs_to :shop
  belongs_to :mailing, class_name: 'DigestMailing', foreign_key: 'digest_mailing_id'
  has_many :digest_mails, dependent: :destroy

  scope :incomplete, -> { where(completed: false) }
  scope :not_test, -> { where(test_email: nil) }

  validates :mailing, presence: true
  validates :shop_id, presence: true
  validates :start_id, presence: true, unless: :test_mode_or_mailchimp_external?
  validates :end_id, presence: true, unless: :test_mode_or_mailchimp_external?


  def test_mode_or_mailchimp_external?
    test_mode? || have_mailchimp_data?
  end

  def test_mode?
    self.test_email.present?
  end

  def have_mailchimp_data?
    self.mailchimp_count.present? && self.mailchimp_offset.present?
  end

  def complete!
    update(completed: true)
  end
end
