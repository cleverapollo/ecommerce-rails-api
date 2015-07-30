class ApplicationController < ActionController::API
  before_action :set_headers
  before_action :sanitize_params

  protected

  # Заголовки для AJAX-запросов
  def set_headers
    headers['Access-Control-Allow-Origin'] = request.headers["HTTP_ORIGIN"]
    headers['Access-Control-Allow-Credentials'] = 'true'
  end

  # Чистим входные параметры от битых данных
  def sanitize_params
    ParamsSanitizer.sanitize!(params)
  end

  # Отдать успешный ответ
  def respond_with_success
    render json: { status: 'success' }
  end

  # Отдать JSON с ошибкой и кодом 400
  def respond_with_client_error(exception)
    render json: { status: 'error', message: exception.to_s }, status: 400
  end

  # Залоггировать клиентскую ошибку
  def log_client_error(exception)
    # client_error = ClientError.create(shop: Shop.find_by(uniqid: params[:shop_id]),
    #                                   exception_class: exception.class.to_s,
    #                                   exception_message: exception.to_s,
    #                                   params: params,
    #                                   referer: request.referer.try(:truncate, 250))

    CLIENT_ERRORS_LOGGER.error(client_error)
  end
end
