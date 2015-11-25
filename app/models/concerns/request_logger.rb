module RequestLogger
  extend ActiveSupport::Concern

  included do
    after_destroy :log_destroy_context
  end

  def self.logger
    @logger ||= Logger.new Rails.root.join("log", "request_logger.log")
  end

  def log_destroy_context
    RequestLogger.logger.info "destroy: #{ self.class.name } #{ self.attributes.to_json } #{ RequestLocals.fetch(:url) } #{ RequestLocals.fetch(:params) }"
  end
end