module StateMachine::Integrations::ActiveModel
  public :around_validation
end

class DigestMailing < ActiveRecord::Base
  belongs_to :shop

  has_many :digest_mailing_batches

  state_machine :state, initial: :new do
    event :prepare_to_send do
      transition :new => :ready_to_send
    end

    event :back_to_new do
      transition :ready_to_send => :new
    end

    event :process do
      transition [:ready_to_send, :failed] => :processed
    end

    event :fail_mailing do
      transition :processed => :failed
    end
  end
end
