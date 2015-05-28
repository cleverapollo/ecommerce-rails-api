class AddCategoriesSalesRateIndex < ActiveRecord::Migration
  def change
    execute <<-SQL
      create index categories_sales_rate on items (categories, sales_rate); analyze items;
    SQL
  end
end
