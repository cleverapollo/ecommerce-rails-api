class CustomLogger
  def self.logger
    @@logger = @@logger ||= Logger.new("#{Rails.root}/log/custom_log.log")
  end
end
