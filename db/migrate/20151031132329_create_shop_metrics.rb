class CreateShopMetrics < ActiveRecord::Migration
  def change
    create_table :shop_metrics do |t|
      t.references :shop
      t.integer :orders, null: false, default: 0
      t.integer :real_orders, null: false, default: 0
      t.decimal :revenue, null: false, default: 0
      t.decimal :real_revenue, null: false, default: 0
      t.decimal :orders_quality, null: false, default: 0
      t.decimal :arpu, null: false, default: 0
      t.decimal :arppu, null: false, default: 0
      t.decimal :conversion, null: false, default: 0
      t.integer :visitors, null: false, default: 0
      t.integer :products_viewed, null: false, default: 0
      t.integer :triggers_enabled_count, null: false, default: 0
      t.decimal :triggers_ctr, null: false, default: 0
      t.integer :triggers_orders, null: false, default: 0
      t.decimal :triggers_revenue, null: false, default: 0
      t.decimal :digests_ctr, null: false, default: 0
      t.integer :digests_orders, null: false, default: 0
      t.decimal :digests_revenue, null: false, default: 0
      t.integer :abandoned_products, null: false, default: 0
      t.decimal :abandoned_money, null: false, default: 0
      t.date :date, null: false
    end
    add_index :shop_metrics, [:shop_id, :date], unique: true
  end
end
