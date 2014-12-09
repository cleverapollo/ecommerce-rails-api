##
# Часть дайджестной рассылки.
#
class DigestMailingBatch < ActiveRecord::Base
  include Redis::Objects
  value :current_processed_audience_id

  belongs_to :digest_mailing

  scope :incomplete, -> { where(completed: false) }

  validates :digest_mailing, presence: true
  validates :start_id, presence: true, unless: :test_mode?
  validates :end_id, presence: true, unless: :test_mode?

  def test_mode?
    self.test_email.present?
  end

  def complete!
    update(completed: true)
  end
end
