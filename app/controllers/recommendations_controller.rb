##
# Контроллер, обрабатывающий получение рекомендаций
#
class RecommendationsController < ApplicationController
  include ShopFetcher

  before_action :fetch_non_restricted_shop

  def get
    # Извлекаем данные из входящих параметров
    extracted_params = Recommendations::Params.extract(params)
    # Запускаем процессор с извлеченными данными
    recommendations = Recommendations::Processor.process(extracted_params)
    render json: recommendations
  rescue Recommendations::Error => e
    log_client_error(e)
    respond_with_client_error(e)
  end
end
