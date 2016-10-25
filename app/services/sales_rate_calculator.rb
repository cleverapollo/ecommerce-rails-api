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
      # Слабое место в суммировании рейтинга, т.к. бывают товары очень дорогие (1.5М рублей), на которые много кто смотрит, но никто не покупает. И у них рейтинг выше среднего.
      # sales_data = shop.actions.where('timestamp > ?', 3.month.ago.to_date.to_time.to_i).group(:item_id).sum('COALESCE(purchase_count, 0) + COALESCE(rating, 0)')
      # sales_data = shop.actions.where('timestamp > ?', 3.month.ago.to_date.to_time.to_i).where('purchase_count > 0').group(:item_id).sum('COALESCE(purchase_count, 0)')
      # Работаем с историей заказов, а не actions, т.к. actions не учитывает историю заказов.
      sales_data = OrderItem.where(order_id: Order.select(:id).where(shop_id: shop.id).where('date >= ?', 3.months.ago)).group(:item_id).sum('COALESCE(amount, 0)')

      # Делаем массив хешей информации о товарах
      items = sales_data.map { |k, v| {item_id: k, purchases: v, price: 0.0, sales_rate: 0.0} }

      # Ищем цены товаров и создаем хеш ID => PRICE
      items_prices = Hash[shop.items.where(id: items.map {|e| e[:item_id]}).pluck(:id, :price)]

      # Добавляем цены в информацию о товарах
      items.each_with_index  do |v, k|
        items[k][:price] = items_prices[v[:item_id]].to_f if items_prices[v[:item_id]].present?
      end

      # Удаляем товары с пустыми ценами
      items.delete_if { |i| i[:price].nil? || i[:price] == 0 }

      # Магазины без данных пропускаем – векторы без значений не могут быть нормализованы, поэтому далее просто обнулятся текущие оценки и все
      if items.length > 0

        # Нормализуем цены (умножаем на 100, потому что бывают товары дешевле рубля)
        v_price = Vector.elements(items.map { |t| (t[:price] * 100.0).to_i })
        v_price_norm = v_price.normalize

        # Нормализуем покупки
        v_purchases = Vector.elements(items.map { |t| t[:purchases] })
        v_purchases_norm = v_purchases.normalize

        # Подсчитываем sales_rate в виде целого числа, но не больше 30000
        items.each_with_index do |_, index|

          items[index][:sales_rate] =  [((K_PRICE * v_price_norm[index] + K_PURCHASES * v_purchases_norm[index]) / (K_PRICE + K_PURCHASES) * 10000).to_i, 30000].min

          # Если SR получился 0, все равно ставим 1, чтобы в рекомендациях при селектах задействовать индексы
          items[index][:sales_rate] = 1 if items[index][:sales_rate] < 1

        end

      end

      # Обновляем sales_rate у товаров. Делаем это группами по схожим sales_rate, чтобы не делать 40000 индивидуальных запросов UPDATE
      # Большие группы разбиваем по 500 товаров, чтобы не получать огромные запросы WHERE id IN (10000 идентификаторов)
      chunks = {}
      items.each do |item|
        if chunks.key?(item[:sales_rate])
          chunks[item[:sales_rate]] << item[:item_id]
        else
          chunks[item[:sales_rate]] = [item[:item_id]]
        end
      end
      begin
        chunks.each do |sales_rate, item_ids|
          item_ids.each_slice(1000) do |ids|
            shop.items.recommendable.where(id: ids).update_all sales_rate: sales_rate
          end
        end
      rescue StandardError => e
        Rollbar.error(e, shop_id: shop.id, shop_name: shop.name, shop_url: shop.url)
      end

      # Обнуляем sales rate у товаров, для которых его не было рассчитано
      if chunks.count > 0
        garbage_items = shop.items.recommendable.where('sales_rate is not null').pluck(:id) - chunks.map {|k, v| v }.sum
        if garbage_items.length > 0
          Item.where(id: garbage_items).update_all sales_rate: nil
        end
      end

      nil
    end


  end
end
