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

    # Если магазин в ограниченном режиме
    if shop.restricted?
      raise Finances::Error.new('Your store is in Restricted Mode. Please contact our support team at desk@rees46.com')
    end

    # Для блоков рекомендаций другая реализация
    if params[:recommender_type] == 'dynamic'
      # @type [RecommenderBlock] recommender_block
      recommender_block = @shop.recommender_blocks.find_by(code: params[:recommender_code])
      raise Recommendations::Error.new('Incorrect recommender code') if recommender_block.nil?
      recommendations = recommender_block.recommends(params)
    else

      # Извлекаем данные из входящих параметров
      extracted_params = Recommendations::Params.new(params)
      extracted_params.shop = @shop
      extracted_params.extract

      # Запускаем процессор с извлеченными данными
      recommendations = Recommendations::Processor.process(extracted_params)

      if extracted_params.shop.id == 1464 && extracted_params.type == 'popular' && recommendations.count < extracted_params.limit
        experiment_params = extracted_params.dup
        experiment_params.track_recommender = false
        experiment_params.limit = extracted_params.limit - recommendations.count
        experiment_params.skip_niche_algorithms = true
        recommendations += Recommendations::Processor.process(experiment_params)
        recommendations.uniq!
      end

      # # Эксперимент для Красотки - главная страница
      if @shop.id == 2413 && extracted_params.type == 'popular' && extracted_params.categories.empty?

        # Оставляем только 3 популярных товара
        recommendations = recommendations[0..5]

        experiment_params = extracted_params.dup

        # Добавляем 3 популярных лака
        experiment_params.track_recommender = false
        experiment_params.limit = 3
        experiment_params.categories = ['514']
        experiment_params.exclude += recommendations
        recommendations += Recommendations::Processor.process(experiment_params)
        recommendations.uniq!

        # # Добавляем 3 сопутствующих к корзине
        # experiment_params.categories = []
        # experiment_params.limit = 3
        # experiment_params.exclude += recommendations
        # experiment_params.type = 'see_also'
        # recommendations += Recommendations::Processor.process(experiment_params)
        # recommendations.uniq!
        #
        # Добиваем популярными
        if recommendations.count < extracted_params.limit
          extracted_params.limit = extracted_params.limit - recommendations.count
          extracted_params.exclude += recommendations
          recommendations += Recommendations::Processor.process(extracted_params)
        end


      end

      # Для триггера "Брошенная категория" отмечаем подписку на категории
      # Если категории есть, конечно.
      if extracted_params.type == 'popular' && extracted_params.categories.is_a?(Array) && extracted_params.categories.length > 0 && TriggerMailing.where(shop_id: @shop.id, trigger_type: 'abandoned_category', enabled: true).exists?
        TriggerMailings::SubscriptionForCategory.subscribe extracted_params.shop, extracted_params.user, ItemCategory.where(shop_id: extracted_params.shop.id).where(external_id: extracted_params.categories).first
      end

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
    raise e if Rails.env.development?
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
