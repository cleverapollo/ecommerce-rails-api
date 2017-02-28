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
    extracted_params = Recommendations::Params.extract(params)

    # Запускаем процессор с извлеченными данными
    recommendations = Recommendations::Processor.process(extracted_params)

    # Для триггера "Брошенная категория" отмечаем подписку на категории
    # Если категории есть, конечно.
    begin
      if extracted_params.type == 'popular' && extracted_params.categories.is_a?(Array) && extracted_params.categories.length > 0 && TriggerMailing.where(shop_id: @shop.id, trigger_type: 'abandoned_category', enabled: true).exists?
        TriggerMailings::SubscriptionForCategory.subscribe extracted_params.shop, extracted_params.user, ItemCategory.where(shop_id: extracted_params.shop.id).where(external_id: extracted_params.categories).first
      end
    rescue TriggerMailings::SubscriptionForCategory::IncorrectMailingSettingsError => e
    end

    if shop.mailings_settings.try(:external_mailganer?)
      redis_db = [0,0,2][ENV['REES46_SHARD'].to_i]
      redis = Redis.new({
        url: "redis://localhost:6379/#{ redis_db }",
        namespace: "rees46_api_#{ Rails.env }"
      })
      key = "recommender.request.#{shop.id}.#{Time.now.utc.to_date}"
      redis.incr(key)
      redis.expire(key, 2.days)
    end

    render json: recommendations


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


  # Массовые рекомендации для пачки полутелей.
  # После расчета рекомендаций делает обратный запрос на указанный Callback URL
  # @param shop_id
  # @param users [Array[Email]]
  def batch

  end


end
