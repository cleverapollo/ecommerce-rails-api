class SalesRateCalculator

  # Минимальное количество продаж для применения нормальной формулы расчета SR
  MINIMUM_SALES_FOR_NORMAL_SALES_RATE = 100

  # Вес цены в формуле расчета
  K_PRICE = 0.1

  # Вес покупок в формуле расчета
  K_PURCHASES = 1.0

  class << self

    # Рассчитывает sales rate для товаров всех магазинов, подключенных больше 3 дней назад (нормальный режим)
    def perform
      Shop.unrestricted.each do |shop|
        self.recalculate_for_shop shop
      end
      nil
    end

    # Рассчитывает sales rate для новых магазинов – чаще, чем основной sales rate
    def perform_newbies
      Shop.newbies.each do |shop|
        self.recalculate_for_shop shop
      end
      nil
    end


    # Рассчитываем sales rate для товаров указанного магазина
    def recalculate_for_shop(shop)

      require 'matrix'

      # Находим экшны проданных за 3 месяца товаров и группируем продажи по этим товарам
      sales_data = shop.actions.where('timestamp > ?', 3.month.ago.to_date.to_time.to_i).group(:item_id).sum('COALESCE(purchase_count * 15.0, 0) + COALESCE(rating, 0)')

      # Если купленных товаров недостаточно, то рассчитываем популярность товаров другим событиям
      # @delete after 20.05.2015
      # if sales_data.length < MINIMUM_SALES_FOR_NORMAL_SALES_RATE
      #   sales_data = shop.actions.where('timestamp > ?', 3.month.ago.to_date.to_time.to_i).group(:item_id).sum(:rating)
      # end

      # Делаем массив хешей информации о товарах
      items = sales_data.map { |k, v| {item_id: k, purchases: v, price: 0.0, sales_rate: 0.0} }

      # Ищем цены товаров
      items_prices = shop.items.where(id: items.map {|e| e[:item_id]}).pluck(:id, :price)

      # Добавляем цены в информацию о товарах
      items.each_with_index  do |v, k|
        idx = items_prices.index { |x| x[0] == v[:item_id] }
        if idx
          items[k][:price] = items_prices[idx][1].to_f
        end
      end
      # items_prices.each do |e|
      #   items.each_with_index do |v, k|
      #     if v[:item_id] == e[0]
      #       items[k][:price] = e[1].to_f
      #       break
      #     end
      #   end
      # end

      # Удаляем товары с пустыми ценами
      items.delete_if { |i| i[:price].nil? || i[:price] == 0 }

      # Магазины без данных пропускаем – векторы без значений не могут быть нормализованы, поэтому далее просто обнулятся текущие оценки и все
      if items.length > 0

        # Нормализуем цены
        v_price = Vector.elements(items.map { |t| t[:price].to_i })
        v_price_norm = v_price.normalize

        # Нормализуем покупки
        v_purchases = Vector.elements(items.map { |t| t[:purchases] })
        v_purchases_norm = v_purchases.normalize

        # Подсчитываем sales_rate в виде целого числа, но не больше 30000
        items.each_with_index do |_, index|
          items[index][:sales_rate] =  [((K_PRICE * v_price_norm[index] + K_PURCHASES * v_purchases_norm[index]) / (K_PRICE + K_PURCHASES) * 10000).to_i, 30000].min
        end

      end

      # Обнуляем sales_rate у всех товаров магазина
      shop.items.recommendable.where('sales_rate is not null').update_all sales_rate: nil

      # Обновляем sales_rate у товаров
      items.each do |item|
        if item[:sales_rate] > 0
          shop.items.recommendable.where(id: item[:item_id]).update_all sales_rate: item[:sales_rate]
        else
          # В качестве отработки ситуации, когда рейтинг совсем небольшой
          shop.items.recommendable.where(id: item[:item_id]).update_all sales_rate: 1
        end
      end

      nil
    end


  end
end