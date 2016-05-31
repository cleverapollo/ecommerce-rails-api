class AddSourceTypeIndexToOrders < ActiveRecord::Migration
  def change
    add_index :orders, [:shop_id, :source_type, :date], where: 'source_type IS NOT NULL'
  end
end
