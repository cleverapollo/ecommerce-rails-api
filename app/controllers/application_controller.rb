class ApplicationController < ActionController::API
  protected
    def respond_with_success
      render json: { status: 'success' }
    end

    def respond_with_client_error(exception)
      Rollbar.report_exception(exception)
      render json: { status: 'error', message: exception.to_s }, status: 400
    end
end
