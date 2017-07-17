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

    # Извлекаем данные из входящих параметров
    extracted_params = Recommendations::Params.new(params)
    extracted_params.shop = @shop
    extracted_params.extract

    # Запускаем процессор с извлеченными данными
    recommendations = Recommendations::Processor.process(extracted_params)


    # # Эксперимент для Красотки - главная страница
    # if @shop.id == 2413 && extracted_params.type == 'popular' && extracted_params.categories.empty?
    #
    #   # Оставляем только 3 популярных товара
    #   recommendations = recommendations[0..2]
    #
    #   experiment_params = extracted_params.dup
    #
    #   # Добавляем 3 популярных лака
    #   experiment_params.track_recommender = false
    #   experiment_params.limit = 3
    #   experiment_params.categories = ['514']
    #   experiment_params.exclude += recommendations
    #   recommendations += Recommendations::Processor.process(experiment_params)
    #   recommendations.uniq!
    #
    #   # Добавляем 3 сопутствующих к корзине
    #   experiment_params.categories = []
    #   experiment_params.limit = 3
    #   experiment_params.exclude += recommendations
    #   experiment_params.type = 'see_also'
    #   recommendations += Recommendations::Processor.process(experiment_params)
    #   recommendations.uniq!
    #
    #   # Добиваем популярными
    #   if recommendations.count < extracted_params.limit
    #     extracted_params.limit = extracted_params.limit - recommendations.count
    #     extracted_params.exclude += recommendations
    #     recommendations += Recommendations::Processor.process(extracted_params)
    #   end
    #
    #
    # end

    # # Дочки - если запра
    # if @shop.id == 725 && extracted_params.type == 'also_bought'
    #   extracted_params.limit = 8
    #   if extracted_params.cart_item_ids && extracted_params.item_id && extracted_params.cart_item_ids.include?(extracted_params.item_id)
    #     # Показываем also_bought
    #     extracted_params.max_price_filter = 1500
    #     extracted_params.type = 'also_bought'
    #     extracted_params.track_recommender = false
    #     recommendations = Recommendations::Processor.process(extracted_params)
    #     extracted_params.max_price_filter = nil
    #   else
    #     # Показываем similar
    #     extracted_params.type = 'similar'
    #     extracted_params.track_recommender = false
    #     recommendations = Recommendations::Processor.process(extracted_params)
    #   end
    #
    # end
    #
    # # Эксперимент в корзине дочек - A - показываем recently_viewed, B - показываем see_also с ограничением по цене
    # if @shop.id == 725 && extracted_params.type == 'see_also'
    #   if extracted_params.segments && extracted_params.segments.first == '1_0'
    #     extracted_params.type = 'recently_viewed'
    #     _extracted = extracted_params.exclude
    #     extracted_params.exclude += Item.where(id: extracted_params.cart_item_ids).pluck(:uniqid) if extracted_params.cart_item_ids.any?
    #     extracted_params.track_recommender = false
    #     recommendations = Recommendations::Processor.process(extracted_params)
    #     extracted_params.exclude = _extracted
    #
    #     if recommendations.count < extracted_params.limit
    #       extracted_params.max_price_filter = 1500
    #       extracted_params.type = 'see_also'
    #       extracted_params.track_recommender = false
    #       recommendations += Recommendations::Processor.process(extracted_params)
    #       extracted_params.max_price_filter = nil
    #     end
    #   else
    #     extracted_params.max_price_filter = 1500
    #     extracted_params.type = 'see_also'
    #     extracted_params.track_recommender = false
    #     recommendations += Recommendations::Processor.process(extracted_params)
    #     extracted_params.max_price_filter = nil
    #   end
    #
    # end
    #
    # if @shop.id == 725
    #   extracted_params.track_recommender = false
    #
    #   # Если нашли меньше, чем нужно для see_also, also_bought
    #   if recommendations.count < extracted_params.limit && %w(see_also also_bought).include?(extracted_params.type)
    #     extracted_params.skip_niche_algorithms = true
    #     extracted_params.exclude += recommendations
    #
    #     # Запускаем процессор с извлеченными данными
    #     recommendations += Recommendations::Processor.process(extracted_params)
    #   end
    #
    #   # Если нашли меньше, чем нужно для also_bought
    #   if recommendations.count < extracted_params.limit && %w(also_bought).include?(extracted_params.type)
    #
    #     # достаем товары из корзины
    #     extracted_params.exclude += recommendations
    #
    #     # Создаем рекомендер
    #     recommender = Recommender::Impl::AlsoBought.new(extracted_params)
    #     recommender.use_cart = true
    #
    #     # Запускаем процессор с извлеченными данными
    #     recommendations += recommender.recommendations
    #   end
    #
    #   # Если нашли меньше, чем нужно для see_also, also_bought
    #   if recommendations.count < extracted_params.limit && %w(see_also also_bought).include?(extracted_params.type)
    #     extracted_params.skip_niche_algorithms = true
    #     extracted_params.exclude += recommendations
    #
    #     # Создаем рекомендер
    #     recommender = Recommender::Impl::AlsoBought.new(extracted_params)
    #     recommender.use_cart = true
    #
    #     # Запускаем процессор с извлеченными данными
    #     recommendations += recommender.recommendations
    #   end
    #
    #   # Если нашли меньше, чем нужно для see_also, also_bought добавляем похожие
    #   if recommendations.count < extracted_params.limit && %w(see_also also_bought).include?(extracted_params.type) && shop.id != 2413
    #     extracted_params.type = 'similar'
    #     extracted_params.exclude += recommendations
    #     extracted_params.exclude = extracted_params.exclude.uniq
    #
    #     # Запускаем процессор с извлеченными данными
    #     recommendations += Recommendations::Processor.process(extracted_params)
    #   end
    #
    #   # Обрзаем возможные лишние товары
    #   recommendations = recommendations.uniq.take(extracted_params.limit)
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
