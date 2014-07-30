class AddValuesToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :recommended_value, :decimal, null: false, default: 0.0
    add_column :orders, :common_value, :decimal, null: false, default: 0.0
  end
end
