class ClientErrorsLogger < Logger
  def format_message(severity, timestamp, progname, msg)
    "#{timestamp.to_formatted_s(:db)} #{severity} #{msg}\n"
  end
end

log_file = File.open("#{Rails.root}/log/client_errors.log", 'a')
log_file.sync = true
CLIENT_ERRORS_LOGGER = ClientErrorsLogger.new(log_file)
