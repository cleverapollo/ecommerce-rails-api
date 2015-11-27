module TriggersLogger
  def self.logger
    @logger ||= Logger.new Rails.root.join("log", "clients_processor.log")
  end

  def self.log(msg)
    TriggersLogger.logger.info msg
  end
end