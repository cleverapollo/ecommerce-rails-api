class DropCategoriesSalesRateIndex < ActiveRecord::Migration
  def change
    remove_index :items, name: :categories_sales_rate
  end
end
