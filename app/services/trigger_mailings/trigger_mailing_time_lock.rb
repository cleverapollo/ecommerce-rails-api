module TriggerMailings
  class TriggerMailingTimeLock
    include Redis::Objects
    value :sending, :expiration => 60.minutes

    def sending_available?
      return false if self.sending == 'true'
      true
    end

    def start_sending!
      self.sending = true
    end

    def stop_sending!
      self.sending = false
    end

    def id
      1
    end
  end
end
