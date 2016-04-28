class AddOldPriceToItem < ActiveRecord::Migration
  def change
    remove_column :items, :old_fucking_categories
    add_column :items, :oldprice, :decimal
  end
end
