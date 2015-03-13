class RunnerWrapper
  class << self
    def run(what)
      begin
        eval(what)
      rescue Exception => e
        Rollbar.error(e)
      end
    end
  end
end
