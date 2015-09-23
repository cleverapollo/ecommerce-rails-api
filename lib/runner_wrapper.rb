class RunnerWrapper
  class << self
    def run(what)
      begin
        eval(what)
      rescue Exception => e
        # @MARK_ROLLBAR_DISABLED
        # Rollbar.error(e)
      end
    end
  end
end
