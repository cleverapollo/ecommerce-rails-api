class AddOrdersToAdvertiserStatistics < ActiveRecord::Migration
  def change
    create_table :advertisers_orders do |t|
      t.belongs_to :advertiser_statistics, index:true
      t.belongs_to :orders
    end
  end
end
