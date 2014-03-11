class ApplicationController < ActionController::API
  before_filter :set_headers

  protected
    def set_headers
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Request-Method'] = '*'
      headers['Access-Control-Allow-Credentials'] = 'true'
    end

    def respond_with_success
      render json: { status: 'success' }
    end

    def respond_with_client_error(exception)
      Rollbar.report_exception(exception)
      render json: { status: 'error', message: exception.to_s }, status: 400
    end
end
