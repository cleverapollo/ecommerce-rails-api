##
# Часть дайджестной рассылки.
#
class DigestMailingBatch < ActiveRecord::Base
  include Redis::Objects
  value :current_processed_client_id

  belongs_to :mailing, class_name: 'DigestMailing', foreign_key: 'digest_mailing_id'
  has_many :digest_mails

  scope :incomplete, -> { where(completed: false) }

  validates :mailing, presence: true
  validates :start_id, presence: true, unless: :test_mode?
  validates :end_id, presence: true, unless: :test_mode?

  def test_mode?
    self.test_email.present?
  end

  def complete!
    update(completed: true)
  end
end
