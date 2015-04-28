##
# Позволяет получать заголовки в контроллере.
#
module SanitizedHeaders
  protected

  def sanitized_header(name)
    case name
    when :user_agent
      sanitize_header(request.env['HTTP_USER_AGENT'])
    when :city
      sanitize_header(request.headers['HTTP_CITY'])
    when :country
      sanitize_header(request.headers['HTTP_COUNTRY'])
    when :language
      sanitize_header(request.env['HTTP_ACCEPT_LANGUAGE'])
    end
  end

  private

  def sanitize_header(value)
    if value.present? && value != 'Undefined'
      StringHelper.encode_and_truncate(value)
    end
  end
end
