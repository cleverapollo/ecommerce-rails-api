namespace :reorganizations do
  desc "Reorganizes categories in Action and Item"
  task categories: :environment do
    Item.find_in_batches do |batch|
      Item.connection.execute("
        UPDATE items 
        SET categories = ARRAY[category_uniqid] 
        WHERE category_uniqid is not null AND category_uniqid != ''
        AND id IN (#{batch.map(&:id).join(',')})
      ")
    end

    Action.find_in_batches do |batch|
      Action.connection.execute("
        UPDATE actions 
        SET categories = ARRAY[category_uniqid] 
        WHERE category_uniqid is not null AND category_uniqid != ''
        AND id IN (#{batch.map(&:id).join(',')})
      ")
    end
  end


  desc "Recalculate orders"
  task recalculate_orders: :environment do
    Order.includes(order_items: :item).where("date >= ?", 1.month.ago).find_each(batch_size: 100) do |order|
      next if order.user.blank? || order.shop.blank?
      items = order.order_items.map{|oi| i = oi.item; i.amount = oi.amount; i }
      values = Order.order_values(order.shop, order.user, items)
      order.update(
        common_value: values[:common_value],
        recommended_value: values[:recommended_value],
        value: values[:value],
        recommended: (values[:recommended_value] > 0)
      )
    end
  end
end
