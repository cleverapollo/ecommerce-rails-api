class ChangeDefaultProductsSubscriptions < ActiveRecord::Migration
  def change
    change_column_default :subscriptions_settings, :products, true
  end
end
