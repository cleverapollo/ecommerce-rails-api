# Сохраняет статистику событий для брендов-клиентов
class BrandLogger

  class << self

    # Записать в статистику информацию о показе за сегодняшнюю дату
    # Либо создает новую запись, если не было за сегодня, либо обновляет существующую
    # @param advertiser_id Integer
    # @param shop_id Integer
    def track_view(advertiser_id, shop_id)
      row = get_statistics_row advertiser_id, Date.current
      row.update views: (row.views + 1)
      AdvertiserShop.where(advertiser_id: advertiser_id).where(shop_id: shop_id).update_all last_event_at: Time.current
    end


    # Трекает количество кликов продвигаемого товара
    # @param advertiser_id Integer
    def track_click(advertiser_id, recommended = false)
      row = get_statistics_row advertiser_id, Date.current
      if recommended
        row.update recommended_clicks: (row.recommended_clicks + 1)
      else
        row.update original_clicks: (row.original_clicks + 1)
      end
    end


    # Трекает количество продаж продвигаемого товара
    # @param advertiser_id Integer
    # @param recommended Boolean
    def track_purchase(advertiser_id, recommended = false)
      row = get_statistics_row advertiser_id, Date.current
      if recommended
        row.update recommended_purchases: (row.recommended_purchases + 1)
      else
        row.update original_purchases: (row.original_purchases + 1)
      end
    end

    # Создает или находит запись о статистике рекламодателя за дату
    # Уникальный индекс, и чтобы не было дубликатов, кидаем ошибку в случае конкуретного создания записей, после чего находим уже созданную запись
    # @param advertiser_id [Integer]
    # @param date [Date]
    # @return AdvertiserStatistic
    def get_statistics_row(advertiser_id, date)
      begin
        row = AdvertiserStatistic.find_or_create_by! advertiser_id: advertiser_id, date: date
      rescue
        row = AdvertiserStatistic.find_by advertiser_id: advertiser_id, date: date
      end
      row
    end


  end

end