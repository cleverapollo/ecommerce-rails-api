module TriggerMailings
  class TriggerMailingTimeLock
    include Redis::Objects
    value :sending_trigger_mails, :expiration => 30.minutes

    def sending_available?
      return false if self.sending_trigger_mails == 'true'
      true
    end

    def start_sending!
      self.sending_trigger_mails = true
    end

    def stop_sending!
      self.sending_trigger_mails = false
    end

    def id
      1
    end
  end
end
