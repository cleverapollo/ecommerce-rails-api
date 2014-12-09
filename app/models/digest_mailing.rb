##
# Дайджестная рассылка.
#
class DigestMailing < ActiveRecord::Base
  class DisabledError < StandardError; end

  include Redis::Objects
  counter :sent_mails_count
  belongs_to :shop

  has_many :digest_mailing_batches

  # Отметить рассылку как прерванную.
  def fail!
    update(state: 'failed')
  end
end
