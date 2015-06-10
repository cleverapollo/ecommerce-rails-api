# Сохраняет статистику событий для брендов-клиентов
class BrandLogger

  class << self

    # Записать в статистику информацию о показе за сегодняшнюю дату
    # Либо создает новую запись, если не было за сегодня, либо обновляет существующую
    # @param advertiser_id Integer
    def track_view(advertiser_id)
      row = AdvertiserStatistic.find_or_create_by advertiser_id: advertiser_id, date: Date.current
      row.update views: (row.views + 1)
    end


    # Трекает количество кликов продвигаемого товара
    # @param advertiser_id Integer
    def track_click(advertiser_id, recommended = false)
      row = AdvertiserStatistic.find_or_create_by advertiser_id: advertiser_id, date: Date.current
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
      row = AdvertiserStatistic.find_or_create_by advertiser_id: advertiser_id, date: Date.current
      if recommended
        row.update recommended_purchases: (row.recommended_purchases + 1)
      else
        row.update original_purchases: (row.original_purchases + 1)
      end
    end

  end

end