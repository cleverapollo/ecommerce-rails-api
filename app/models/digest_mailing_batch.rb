class DigestMailingBatch < ActiveRecord::Base
  belongs_to :digest_mailing

  scope :incompleted, -> { where(completed: false) }
end
