class RemovePriceFromActions < ActiveRecord::Migration
  def change
    remove_column :actions, :price
  end
end
