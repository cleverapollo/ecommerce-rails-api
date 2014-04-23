class AddValueFieldsToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :value, :decimal, default: 0.0, null: false
    add_column :orders, :recommended, :boolean, default: false, null: false
    add_column :orders, :ab_testing_group, :integer

    Order.includes(order_items: :item, user: :shops_users).find_each do |order|
      order.value = order.order_items.map{|o_i| (o_i.amount || 1) * (o_i.item.price || 0) }.sum
      order.recommended = order.order_items.select{|o_i| o_i.recommended_by.present? }.any?
      shop_user_relation = if order.user.present?
        order.user.shops_users.select{|s_u| s_u.shop_id == order.shop_id }.first
      else
        nil
      end
      order.ab_testing_group = shop_user_relation.present? ? shop_user_relation.ab_testing_group : nil
      order.save
    end
  end
end
