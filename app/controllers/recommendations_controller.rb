##
# Контроллер, обрабатывающий получение рекомендаций
#
class RecommendationsController < ApplicationController
  include ShopFetcher

  before_action :fetch_non_restricted_shop

  def get

    # Проверяем подписки. Если есть фиксированные и не оплачены, то отдаем ошибку
    # Важно: если подписка деактивирована, то рекомендации работать будут.
    # Непонятно, плохо это или хорошо.
    if shop.subscription_plans.rees46_recommendations.active.overdue.exists?
      raise Exception('Subscriptions inactive. Recommendations disabled. Please, contact to your manager.')
    end

    # Извлекаем данные из входящих параметров
    extracted_params = Recommendations::Params.extract(params)

    # Запускаем процессор с извлеченными данными
    recommendations = Recommendations::Processor.process(extracted_params)

    # Для триггера "Брошенная категория" отмечаем подписку на категории
    # Если категории есть, конечно.
    begin
      if extracted_params.type == 'popular' && extracted_params.categories.is_a?(Array) && extracted_params.categories.length > 0
        TriggerMailings::SubscriptionForCategory.subscribe extracted_params.shop, extracted_params.user, ItemCategory.where(shop_id: extracted_params.shop.id).where(external_id: extracted_params.categories).first
      end
    rescue TriggerMailings::SubscriptionForCategory::IncorrectMailingSettingsError => e
    end

    render json: recommendations


  rescue Exception => e
    # Костыль
    log_client_error(e)
    respond_with_client_error(e)
  rescue Recommendations::Error => e
    log_client_error(e)
    respond_with_client_error(e)
  end
end
