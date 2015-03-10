##
# Контроллер, обрабатывающий получение рекомендаций
#
class RecommendationsController < ApplicationController
  def get
    if Shop.find_by(uniqid: params[:shop_id]).try(:restricted?)
      render(json: []) and return false
    end

    extracted_params = Recommendations::Params.extract(params)
    result = Recommendations::Processor.process(extracted_params)
    render json: result
  rescue Recommendations::Error => e
    log_client_error(e)
    respond_with_client_error(e)
  end
end
