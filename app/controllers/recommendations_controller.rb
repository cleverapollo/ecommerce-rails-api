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
    if @shop.id == 725
      extracted_params.track_recommender = false

      # Если нашли меньше, чем нужно для see_also, also_bought
      if recommendations.count < extracted_params.limit && %w(see_also also_bought).include?(extracted_params.type)
        extracted_params.industrial_kids = false
        extracted_params.exclude += recommendations

        # Запускаем процессор с извлеченными данными
        recommendations += Recommendations::Processor.process(extracted_params)
      end

      # Если нашли меньше, чем нужно для also_bought
      if recommendations.count < extracted_params.limit && %w(also_bought).include?(extracted_params.type)

        # достаем товары из корзины
        extracted_params.exclude += recommendations

        # Создаем рекомендер
        recommender = Recommender::Impl::AlsoBought.new(extracted_params)
        recommender.use_cart = true

        # Запускаем процессор с извлеченными данными
        recommendations += recommender.recommendations
      end

      # Если нашли меньше, чем нужно для see_also, also_bought
      if recommendations.count < extracted_params.limit && %w(see_also also_bought).include?(extracted_params.type)
        extracted_params.industrial_kids = false
        extracted_params.exclude += recommendations

        # Создаем рекомендер
        recommender = Recommender::Impl::AlsoBought.new(extracted_params)
        recommender.use_cart = true

        # Запускаем процессор с извлеченными данными
        recommendations += recommender.recommendations
      end

      # Если нашли меньше, чем нужно для see_also, also_bought добавляем похожие
      if recommendations.count < extracted_params.limit && %w(see_also also_bought).include?(extracted_params.type) && shop.id != 2413
        extracted_params.type = 'similar'
        extracted_params.exclude += recommendations
        extracted_params.exclude = extracted_params.exclude.uniq

        # Запускаем процессор с извлеченными данными
        recommendations += Recommendations::Processor.process(extracted_params)
      end

      # Обрзаем возможные лишние товары
      recommendations = recommendations.uniq.take(extracted_params.limit)
    end

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
