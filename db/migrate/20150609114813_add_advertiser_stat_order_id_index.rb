class AddAdvertiserStatOrderIdIndex < ActiveRecord::Migration
  def change
    add_index :advertisers_orders, [:advertiser_statistics_id, :orders_id], name: 'orders_to_stat', unique: true
  end
end
