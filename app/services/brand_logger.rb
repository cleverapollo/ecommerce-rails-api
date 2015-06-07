# Сохраняет статистику событий для брендов-клиентов
class BrandLogger

  class << self

    # Записать в статистику информацию о показе за сегодняшнюю дату
    # Либо создает новую запись, если не было за сегодня, либо обновляет существующую
    # @param advertiser_id Integer
    def track_view(advertiser_id)
      if (row = AdvertiserStatistic.where(advertiser_id: advertiser_id).where(date: Date.current).first)
        row.update views: (row.views + 1)
      else
        AdvertiserStatistic.create advertiser_id: advertiser_id, views: 1, date: Date.current
      end
    end


    # Трекает количество кликов продвигаемого товара
    # @param advertiser_id Integer
    def track_click(advertiser_id)
      if (row = AdvertiserStatistic.where(advertiser_id: advertiser_id).where(date: Date.current).first)
        row.update clicks: (row.clicks + 1)
      else
        AdvertiserStatistic.create advertiser_id: advertiser_id, clicks: 1, date: Date.current
      end
    end


    # Трекает количество продаж продвигаемого товара
    # @param advertiser_id Integer
    # @param recommended Boolean
    def track_purchase(advertiser_id, recommended = false)
      if (row = AdvertiserStatistic.where(advertiser_id: advertiser_id).where(date: Date.current).first)
        if recommended
          row.update recommended_purchases: (row.recommended_purchases + 1)
        else
          row.update original_purchases: (row.original_purchases + 1)
        end
      else
        if recommended
          AdvertiserStatistic.create advertiser_id: advertiser_id, recommended_purchases: 1, date: Date.current
        else
          AdvertiserStatistic.create advertiser_id: advertiser_id, original_purchases: 1, date: Date.current
        end
      end
    end

  end

end