##
# Контроллер, обрабатывающий получение рекомендаций
#
class RecommendationsController < ApplicationController
  include ActionController::Cookies
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

    current_session_code = cookies['rees46_session_code'] || params[:seance]

    # Для блоков рекомендаций другая реализация
    if params[:recommender_type] == 'dynamic'
      # @type [RecommenderBlock] recommender_block
      recommender_block = @shop.recommender_blocks.find_by(code: params[:recommender_code])
      raise Recommendations::Error.new('Incorrect recommender code') if recommender_block.nil?
      recommendations = recommender_block.recommends(params, current_session_code)
    else

      # Извлекаем данные из входящих параметров
      extracted_params = Recommendations::Params.new(params)
      extracted_params.shop = @shop
      extracted_params.current_session_code = current_session_code
      extracted_params.request = request
      extracted_params.brand_promotions = true
      extracted_params.extract

      # Отключил на черную пятницу
      extracted_params.skip_niche_algorithms = false

      # Тестовый сервис для демошопа
      # if @shop.id == 1464 && extracted_params.type == 'popular'
      #   begin
      #     result = RecommenderService.instance.recommend(@shop.id, extracted_params.type, extracted_params.user.id, extracted_params.session.id, [], extracted_params.exclude_item_ids, extracted_params.limit)
      #     CustomLogger.logger.warn("RS: #{result.inspect}")
      #   rescue Exception => e
      #     Rollbar.error 'RecommenderService', e
      #   end
      # end

      # Запускаем процессор с извлеченными данными
      recommendations = Recommendations::Processor.process(extracted_params)

      if extracted_params.shop.id == 1464 && extracted_params.type == 'popular' && recommendations.count < extracted_params.limit
        experiment_params = extracted_params.dup
        experiment_params.track_recommender = false
        experiment_params.limit = extracted_params.limit - recommendations.count
        experiment_params.skip_niche_algorithms = true
        extracted_params.brand_promotions = false
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
  rescue Recommendations::Error => e
    raise e unless Rails.env.production?
    log_client_error(e)
    respond_with_client_error(e)
  end

  # Brand promotion popup
  def popup

    # Находим инвентарь магазина
    shop_inventory = @shop.shop_inventories.popup.first
    return render json: {} if shop_inventory.blank?

    # Извлекаем данные из входящих параметров
    params[:recommender_type] = 'popular'
    params[:limit] = shop_inventory.settings[:item_count]
    params[:extended] = true
    extracted_params = Recommendations::Params.new(params)
    extracted_params.shop = @shop
    extracted_params.current_session_code = cookies['rees46_session_code'] || params[:seance]
    extracted_params.request = request
    extracted_params.track_recommender = false
    extracted_params.brand_promotions = true
    extracted_params.shop_inventories = [shop_inventory]
    extracted_params.extract

    # Запускаем процессор с извлеченными данными
    recommendations = Recommendations::Processor.process(extracted_params)

    render json: {
        title: shop_inventory.settings[:title],
        items: recommendations
    }
  end

  # Brand sponsored products
  def sponsored

    if params[:id].blank?
      render json: { status: 'error', message: 'Incorrect inventory id' }, status: 400
      return
    end

    # Находим инвентарь магазина
    shop_inventory = @shop.shop_inventories.sponsored.find(params[:id])
    return render json: {} if shop_inventory.blank?

    ids = []

    user_fetcher = UserFetcher.new(shop: @shop, ssid: params[:ssid])
    user = user_fetcher.fetch
    session = user_fetcher.session

    brand_params = OpenStruct.new({
        session: session,
        current_session_code: cookies['rees46_session_code'] || params[:seance],
        shop: @shop,
        type: 'sponsored',
        request: request,
    })

    catch :done do
      relation = shop_inventory.vendor_campaigns.order(max_cpc_price: :desc)
      relation = relation.where('all_categories = TRUE OR ARRAY[?]::varchar[] && categories', params[:category]) if params[:category].present?
      # Проходим по списку кампаний
      relation.each do
        # @type [VendorCampaign] vendor_campaign
        |vendor_campaign|

        # Ищем брендовые товары
        items = @shop.items.recommendable.by_brands(vendor_campaign.brand.downcase).limit([shop_inventory.settings[:item_count].to_i - ids.size, vendor_campaign.item_count].min)
        items = items.in_categories([params[:category]], { any: true }) if params[:category].present?
        items = items.in_categories(vendor_campaign.categories, { any: true }) if vendor_campaign.categories.present? && !vendor_campaign.all_categories
        items.pluck(:uniqid).each do |item|
          vendor_campaign.track_view(brand_params, item)
          ids << item
        end

        # проверяем места на занятость
        throw :done if ids.size >= shop_inventory.settings[:item_count].to_i

      end
    end

    render json: ids
  rescue Exception => e
    # Костыль
    raise e if Rails.env.development?
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
