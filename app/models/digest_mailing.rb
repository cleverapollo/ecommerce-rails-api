module StateMachine::Integrations::ActiveModel
  public :around_validation
end

class DigestMailing < ActiveRecord::Base
  include Redis::Objects
  counter :sent_mails_count
  belongs_to :shop

  has_many :digest_mailing_batches

  state_machine :state do
    event :fail_mailing do
      transition :processing => :failed
    end
  end
end
