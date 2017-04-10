class ApplicationController < ActionController::API
  before_action :set_headers

  protected

  # Заголовки для AJAX-запросов
  # перенесено в nginx
  def set_headers
    if Rails.env.development?
      headers['Access-Control-Allow-Origin'] = request.headers["HTTP_ORIGIN"]
      headers['Access-Control-Allow-Credentials'] = 'true'
    end
    # headers['Access-Control-Allow-Methods'] = 'POST, GET, OPTIONS'
    # headers['Access-Control-Allow-Headers'] = 'Origin'
    # headers['Access-Control-Allow-Headers'] = 'Content-Type'
  end

  before_action :store_request_params!

  # Отдать успешный ответ
  def respond_with_success
    render json: { status: 'success' }
  end

  # Отдать JSON с ошибкой и кодом 400
  def respond_with_client_error(exception)
    render json: { status: 'error', message: exception.to_s }, status: 400
  end

  def respond_with_payment_error(exception)
    render json: { status: 'error', message: exception.to_s }, status: 402
  end

  def respond_with_not_found_error(exception)
    render json: { status: 'error', message: exception.to_s }, status: 404
  end

  # Залоггировать клиентскую ошибку
  def log_client_error(exception)
    client_error = ClientError.create(shop: Shop.find_by(uniqid: params[:shop_id]),
                                      exception_class: exception.class.to_s,
                                      exception_message: exception.to_s,
                                      params: params,
                                      referer: request.referer.try(:truncate, 250))

    CLIENT_ERRORS_LOGGER.error(client_error)
    Rollbar.error(exception) if exception.class != Recommendations::IncorrectParams && exception.class != TriggerMailings::SubscriptionForCategory::IncorrectMailingSettingsError
  end

  def store_request_params!
    RequestLocals.store[:url] = request.original_url
    RequestLocals.store[:params] = params
  end
end
