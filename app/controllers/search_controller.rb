##
# Контроллер, обрабатывающий получение результатов поиска
#
class SearchController < ApplicationController
  include ShopFetcher

  before_action :fetch_non_restricted_shop

  def get

    # Проверяем подписки. Если нет оплаченных и активных, то кидаем код 402 Payment Needed
    if !shop.subscription_plans.product_search.active.paid.exists?
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


    # JSON body
    body = Jbuilder.encode do |json|
      json.products result[:products] do |item|
        json.name     item.name
        json.url      item.url
        json.picture  item.resized_image_by_dimension('100x100')
        json.price    ActiveSupport::NumberHelper.number_to_rounded(item.price, precision: 0, delimiter: " ")
        json.currency shop.currency
      end
      json.categories result[:categories] do |category|
        json.name     category[:name]
        json.id       category[:id]
        json.url      category[:url]
      end
      json.virtual_categories []
      json.keywords []
    end

    # Для полного поиска запоминаем для юзера запрос
    if extracted_params.search_query && extracted_params.type == 'full_search'
      SearchQuery.find_or_create_by user_id: extracted_params.user.id, shop_id: extracted_params.shop.id, date: Date.current, query: extracted_params.search_query
    end

    render json: body

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
