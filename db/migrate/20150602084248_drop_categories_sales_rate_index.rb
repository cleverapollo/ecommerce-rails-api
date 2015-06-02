class DropCategoriesSalesRateIndex < ActiveRecord::Migration
  def change
    execute "DROP INDEX categories_sales_rate;"
  end
end
