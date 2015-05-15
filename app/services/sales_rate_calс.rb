##
# Производит рассчет sales rate на товарах всего магазина
# @more: http://memo.mkechinov.ru/pages/viewpage.action?pageId=3145846
#
class SalesRateCalc

  K_PRICE = 0.6
  K_PURCHASES = 1.0

  class << self

    #Обновить sales rate (SR) всех товаров в магазине
    #SR = (k_price * PriceNormalized + k_purchases * PurchasesNormalized) / (k_price + k_purchases)
    def perform

      Shop.active.find_each do |shop|

        calculated_items = []
        max_price = 0
        max_purchase_count = 0

        items_last_action = timestamp_filter(shop.actions).group(:item_id).select('item_id')

        shop.items.available.where(id:items_last_action).find_each(batch_size: 200) do |item|
          calc_item = {
              id: item.id,
              purchase_count: timestamp_filter(item.actions).sum(:purchase_count),
              price: item.price
          }
          max_price = calc_item[:price] if calc_item[:price]>max_price
          max_purchase_count = calc_item[:purchase_count] if calc_item[:purchase_count]>max_purchase_count
          calculated_items.push(calc_item)
        end

        price_norm = 0
        purchase_norm = 0

        Item.where.not(id:items_last_action).update_all(sr:0)

        calculated_items.each do |item|
          price_norm = item[:price].to_f/max_price
          purchase_norm = item[:purchase_count].to_f/max_purchase_count
          item[:sr]=(K_PRICE*price_norm + K_PURCHASES*purchase_norm)/(K_PRICE+K_PURCHASES)
          Item.update(item[:id], sr: item[:sr])
        end

        ap event:'Shop complete', shop:shop unless Rails.env.test?

      end
    end

    def timestamp_filter(rel)
      rel.where('timestamp > ?', 3.month.ago.to_date.to_time.to_i)
    end
  end
end
