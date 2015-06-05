class AddStatusToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :status, :integer, length: 1, default: 0, null: false
    add_column :orders, :status_date, :date
    add_index :orders, [:shop_id, :status, :status_date]
  end
end
