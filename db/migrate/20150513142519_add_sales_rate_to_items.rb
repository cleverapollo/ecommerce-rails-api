class AddSalesRateToItems < ActiveRecord::Migration
  def change
    add_column :items, :sr, :float
  end
end
