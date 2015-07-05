##
# Дайджестная рассылка.
#
class DigestMailing < ActiveRecord::Base

  establish_connection MASTER_DB if !Rails.env.test?

  class DisabledError < StandardError; end

  include Redis::Objects
  counter :sent_mails_count
  belongs_to :shop

  has_many :batches, class_name: 'DigestMailingBatch'

  # Отметить рассылку как прерванную.
  def fail!
    update(state: 'failed')
  end

  def failed?
    self.state == 'failed'
  end

  def started?
    self.state == 'started'
  end

  def finish!
    update(state: 'finished', finished_at: Time.current)
  end

  # Возобновить сломавшуюся рассылку
  def resume!
    update(state: 'started')
    batches.incomplete.each{|batch| DigestMailingBatchWorker.perform_async(batch.id) }
  end
end
