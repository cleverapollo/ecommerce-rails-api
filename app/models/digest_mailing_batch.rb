class DigestMailingBatch < ActiveRecord::Base
  include Redis::Objects
  value :current_processed_id

  belongs_to :digest_mailing

  scope :incompleted, -> { where(completed: false) }
end
