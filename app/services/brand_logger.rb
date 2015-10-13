# Сохраняет статистику событий для брендов-клиентов
class BrandLogger

  class << self

    # Записать в статистику информацию о показе за сегодняшнюю дату
    # Либо создает новую запись, если не было за сегодня, либо обновляет существующую
    # @param brand_campaign_id [Integer]
    # @param shop_id [Integer]
    # @param recommender [String] Код рекомендера
    def track_view(brand_campaign_id, shop_id, recommender)
      row = get_statistics_row brand_campaign_id, Date.current
      row.update views: (row.views + 1)
      brand_campaign_shops = BrandCampaignShop.where(brand_campaign_id: brand_campaign_id).where(shop_id: shop_id).limit(1) # limit для ускорения, чтобы всю базу не копать
      brand_campaign_shops.update_all last_event_at: Time.current

      # Записываем детальную статистику
      brand_campaign_shops.each do |brand_campaign_shop|
        BrandCampaignStatisticsEvent.create! brand_campaign_shop_id: brand_campaign_shop.id,
          brand_campaign_statistic_id: row.id,
          event: 'view',
          recommended: true,
          recommender: recommender
      end
    end


    # Трекает количество кликов продвигаемого товара
    # @param brand_campaign_id [Integer]
    # @param shop_id [Integer]
    # @param recommender [String]
    def track_click(brand_campaign_id, shop_id, recommender = nil)
      row = get_statistics_row brand_campaign_id, Date.current
      if recommender.present?
        row.update recommended_clicks: (row.recommended_clicks + 1)
      else
        row.update original_clicks: (row.original_clicks + 1)
      end

      # Записываем детальную статистику
      brand_campaign_shops = BrandCampaignShop.where(brand_campaign_id: brand_campaign_id).where(shop_id: shop_id).limit(1) # limit для ускорения, чтобы всю базу не копать
      brand_campaign_shops.each do |brand_campaign_shop|
        BrandCampaignStatisticsEvent.create! brand_campaign_shop_id: brand_campaign_shop.id,
                                             brand_campaign_statistic_id: row.id,
                                         event: 'click',
                                         recommended: recommender.present?,
                                         recommender: recommender
      end
    end


    # Трекает количество продаж продвигаемого товара
    # @param brand_campaign_id Integer
    # @param shop_id [Integer]
    # @param recommender [String]
    def track_purchase(brand_campaign_id, shop_id, recommender = nil)
      row = get_statistics_row brand_campaign_id, Date.current
      if recommender.present?
        row.update recommended_purchases: (row.recommended_purchases + 1)
      else
        row.update original_purchases: (row.original_purchases + 1)
      end

      # Записываем детальную статистику
      brand_campaign_shops = BrandCampaignShop.where(brand_campaign_id: brand_campaign_id).where(shop_id: shop_id).limit(1) # limit для ускорения, чтобы всю базу не копать
      brand_campaign_shops.each do |brand_campaign_shop|
        BrandCampaignStatisticsEvent.create! brand_campaign_shop_id: brand_campaign_shop.id,
                                          brand_campaign_statistic_id: row.id,
                                          event: 'purchase',
                                          recommended: recommender.present?,
                                          recommender: recommender
      end
    end

    # Создает или находит запись о статистике рекламодателя за дату
    # Уникальный индекс, и чтобы не было дубликатов, кидаем ошибку в случае конкуретного создания записей, после чего находим уже созданную запись
    # @param brand_campaign_id [Integer]
    # @param date [Date]
    # @return BrandCampaignStatistic
    def get_statistics_row(brand_campaign_id, date)
      begin
        row = BrandCampaignStatistic.find_or_create_by! brand_campaign_id: brand_campaign_id, date: date
      rescue
        row = BrandCampaignStatistic.find_by brand_campaign_id: brand_campaign_id, date: date
      end
      row
    end


  end

end