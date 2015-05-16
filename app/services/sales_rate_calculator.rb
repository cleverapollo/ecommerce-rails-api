class SalesRateCalculator
  class << self


    # Рассчитывает sales rate для товаров всех магазинов
    def perform
      require 'matrix'
      Shop.unrestricted.each do |shop|
        self.recalculate_for_shop shop
      end
      nil
    end


    # Рассчитываем sales rate для товаров указанного магазина
    def recalculate_for_shop(shop)

      # Находим экшны проданных за 3 месяца товаров и группируем продажи по этим товарам
      sales_data = shop.actions.where('timestamp > ?', 3.month.ago.to_date.to_time.to_i).where('purchase_count > 0').group(:item_id).sum(:purchase_count)

      # Делаем массив хешей информации о товарах
      items = sales_data.map { |k, v| {item_id: k, purchases: v, price: 0.0, sales_rate: 0.0} }
      # items.sort_by! { |v| v[:item_id] }

      # Ищем цены товаров
      items_prices = shop.items.where(id: items.map {|e| e[:item_id]}).pluck(:id, :price)

      # Добавляем цены в информацию о товарах
      items_prices.each do |e|
        items.each_with_index do |v, k|
          if v[:item_id] == e[0]
            items[k][:price] = e[1].to_f
            break
          end
        end
      end

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

        # Подсчитываем sales_rate в виде целого числа
        k_price = 0.4     # Вес цены
        k_purchase = 1    # Вес количества покупок
        items.each_with_index do |item, index|
          items[index][:sales_rate] =  ((k_price * v_price_norm[index] + k_purchase * v_purchases_norm[index]) / (k_price + k_purchase) * 10000).to_i
        end

      end

      # Обнуляем sales_rate у всех товаров магазина
      shop.items.recommendable.where('sales_rate is not null').update_all sales_rate: nil

      # Обновляем sales_rate у товаров
      items.each do |item|
        if item[:sales_rate] > 0
          shop.items.recommendable.where(id: item[:item_id]).update_all sales_rate: item[:sales_rate]
        end
      end

      nil
    end


  end
end