##
# Контроллер, обрабатывающий получение рекомендаций
#
class RecommendationsController < ApplicationController
  include ShopFetcher

  before_action :fetch_non_restricted_shop

  def get

    # Проверяем подписки. Если нет оплаченных и активных, то кидаем код 402 Payment Needed
    if !shop.subscription_plans.product_recommendations.active.paid.exists?
      raise Finances::Error.new('Subscriptions inactive. Recommendations disabled. Please, contact to your manager.')
    end

    # Извлекаем данные из входящих параметров
    extracted_params = Recommendations::Params.new(params)
    extracted_params.shop = @shop
    extracted_params.extract

    # Запускаем процессор с извлеченными данными
    recommendations = Recommendations::Processor.process(extracted_params)

    # Если ничего не нашли для also_bought меняем на see_also
    # if recommendations.blank? && extracted_params.type == 'also_bought'
    #   extracted_params.type = 'see_also'
    #
    #   # достаем товары из корзины
    #   extracted_params.cart_item_ids = ClientCart.where(user: extracted_params.user, shop: extracted_params.shop).first.try(:items) || []
    #
    #   # Запускаем процессор с извлеченными данными
    #   recommendations = Recommendations::Processor.process(extracted_params)
    #
    # end

    # Если ничего не нашли для see_also меняем на popular
    # if recommendations.blank? && extracted_params.type == 'see_also'
    #   extracted_params.type = 'popular'
    #
    #   # Запускаем процессор с извлеченными данными
    #   recommendations = Recommendations::Processor.process(extracted_params)
    # end

    # Для триггера "Брошенная категория" отмечаем подписку на категории
    # Если категории есть, конечно.
    if extracted_params.type == 'popular' && extracted_params.categories.is_a?(Array) && extracted_params.categories.length > 0 && TriggerMailing.where(shop_id: @shop.id, trigger_type: 'abandoned_category', enabled: true).exists?
      TriggerMailings::SubscriptionForCategory.subscribe extracted_params.shop, extracted_params.user, ItemCategory.where(shop_id: extracted_params.shop.id).where(external_id: extracted_params.categories).first
    end

    if shop.mailings_settings.try(:external_mailganer?)
      key = "recommender.request.#{shop.id}.#{Time.now.utc.to_date}"
      Redis.current.incr(key)
      Redis.current.expire(key, 2.days)
    end

    render json: recommendations

  rescue Finances::Error => e
    respond_with_payment_error(e)
  rescue Exception => e
    # Костыль
    log_client_error(e)
    respond_with_client_error(e)
  rescue TriggerMailings::SubscriptionForCategory::IncorrectMailingSettingsError => e
    log_client_error(e)
    respond_with_client_error(e)
  rescue Recommendations::Error => e
    log_client_error(e)
    respond_with_client_error(e)
  end


  # Массовые рекомендации для пачки полутелей.
  # После расчета рекомендаций делает обратный запрос на указанный Callback URL
  # @param shop_id
  # @param users [Array[Email]]
  def batch

  end


end
