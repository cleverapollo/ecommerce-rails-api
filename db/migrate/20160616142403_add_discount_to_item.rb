class AddDiscountToItem < ActiveRecord::Migration
  def change
    add_column :items, :discount, :boolean
    add_index :items, [:shop_id, :discount], where: '(discount is not null)'
  end
end
