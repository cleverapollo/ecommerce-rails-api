class ApplicationController < ActionController::API
  before_action :set_headers

  protected
    def set_headers
      headers['Access-Control-Allow-Origin'] = request.headers["HTTP_ORIGIN"]
      headers['Access-Control-Allow-Credentials'] = 'true'
    end

    def respond_with_success
      render json: { status: 'success' }
    end

    def log_client_error(exception)
      client_error = ClientError.create(shop: Shop.find_by(uniqid: params[:shop_id]),
                                        exception_class: exception.class.to_s,
                                        exception_message: exception.to_s,
                                        params: params)

      CLIENT_ERRORS_LOGGER.error(client_error)
    end

    def respond_with_client_error(exception)
      render json: { status: 'error', message: exception.to_s }, status: 400
    end
end
