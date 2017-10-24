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

    # Настройки поиска магазина
    search_setting, search_keyword = shop.search_setting, extracted_params.search_query.downcase.strip
    NoResultQuery.where(shop_id: extracted_params.shop.id).where('query = ? OR synonym = ?', search_keyword, search_keyword).update_all('query_count = query_count + 1')

    # Get search query redirect 
    search_query_redirect = @shop.search_query_redirects.by_query(search_keyword).first

    # JSON body
    body = Jbuilder.encode do |json|
      json.products result[:products] do |item|
        json.id       item.uniqid
        json.name     item.name
        json.url      UrlParamsHelper.add_params_to(item.url, recommended_by: extracted_params.type, r46_search_query: extracted_params.search_query)
        json.picture  item.resized_image_by_dimension('160x160')
        json.price    ActiveSupport::NumberHelper.number_to_rounded(item.price, precision: 0, delimiter: " ")
        json.currency shop.currency
      end
      json.categories result[:categories] do |category|
        json.name     category[:name]
        json.id       category[:id]
        json.url      UrlParamsHelper.add_params_to(category[:url], recommended_by: extracted_params.type, r46_search_query: extracted_params.search_query)
      end
      json.virtual_categories []
      json.keywords []
      json.queries result[:queries] do |query|
        json.name     query
        json.url      UrlParamsHelper.add_params_to(search_setting.landing_page, recommended_by: extracted_params.type, r46_search_query: query)
      end
      json.collections result[:collections] do |collection|
        json.id     collection[:id]
        json.name   collection[:name]
      end
      json.search_query_redirects do 
        json.query search_query_redirect.query
        json.redirect_link "#{search_query_redirect.redirect_link}?recommended_by=full_search&r46_search_query=#{search_keyword}"
      end if search_query_redirect.present?
    end

    # Для полного поиска запоминаем для юзера запрос
    if extracted_params.search_query && extracted_params.type == 'full_search'
      SearchQuery.find_or_create_by user_id: extracted_params.user.id, shop_id: extracted_params.shop.id, date: Date.current, query: extracted_params.search_query
      NoResultQuery.find_or_create_by(shop_id: extracted_params.shop.id, query: search_keyword) unless result.values.flatten.any?
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



  # Get products for search thematic collection
  def collection

    # Does shop has active subscription? If not, raise 402 Payment Needed
    if !shop.subscription_plans.product_search.active.paid.exists?
      raise Finances::Error.new('Subscriptions inactive. Recommendations disabled. Please, contact to your manager.')
    end

    # Is shop restricted?
    if shop.restricted?
      raise Finances::Error.new('Your store is in Restricted Mode. Please contact our support team at desk@rees46.com')
    end

    # Find user
    session = Session.find_by_code(params[:ssid])
    raise Recommendations::IncorrectParams.new('Invalid session') if session.blank?
    user = session.user

    # Find collection or raise 404
    collection = shop.thematic_collections.find(params[:id])

    # Return result
    render json: SearchEngine::SearchCollection.new(shop, user, collection).recommendations

  end


end
