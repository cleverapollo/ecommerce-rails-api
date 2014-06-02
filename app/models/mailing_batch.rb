class MailingBatch < ActiveRecord::Base
  attr_accessor :started_at

  serialize :users, JSON
  serialize :failed, JSON
  store :statistics, coder: JSON

  belongs_to :mailing

  validates :mailing, presence: true
  validates :users, presence: true
  validates :state, presence: true
  validates :statistics, presence: true

  after_initialize :assign_default_values, if: :new_record?

  def process!
    update_attribute(:state, 'processing')
    @started_at = Time.now
  end

  def finish!
    update_attribute(:state, 'finished')
    statistics[:duration] = Time.now - started_at
  end

  def fail!
    update_attribute(:state, 'failed')
  end

  protected

  def assign_default_values
    self.failed = []
    self.statistics = {
      total: 0,
      with_recommendations: 0,
      no_recommendations: 0,
      failed: 0,
      duration: 0,
      recommendations_statistics: { }
    }
  end
end
