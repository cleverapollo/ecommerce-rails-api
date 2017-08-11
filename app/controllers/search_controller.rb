##
# Контроллер, обрабатывающий получение результатов поиска
#
class SearchController < ApplicationController
  include ShopFetcher

  before_action :fetch_non_restricted_shop

  def get

    # Проверяем подписки. Если нет оплаченных и активных, то кидаем код 402 Payment Needed
    if !shop.subscription_plans.search.active.paid.exists?
      raise Finances::Error.new('Subscriptions inactive. Recommendations disabled. Please, contact to your manager.')
    end

    # Если магазин в ограниченном режиме
    if shop.restricted?
      raise Finances::Error.new('Your store is in Restricted Mode. Please contact our support team at desk@rees46.com')
    end

    # Извлекаем данные из входящих параметров
    extracted_params = SearchEngine::Params.new(params)
    extracted_params.shop = @shop
    extracted_params.extract

    # Запускаем процессор с извлеченными данными
    result = SearchEngine::Processor.process(extracted_params)

    render json: result

  rescue Finances::Error => e
    respond_with_payment_error(e)
  rescue Exception => e
    # Костыль
    log_client_error(e)
    respond_with_client_error(e)
  rescue Recommendations::Error => e
    log_client_error(e)
    respond_with_client_error(e)
  end





end
