class AddShopIdToShardedTables < ActiveRecord::Migration
  def change
    add_column :digest_mailing_batches, :shop_id, :integer
    DigestMailingBatch.all.each do |row|
      if row.mailing.nil?
        row.destroy
      else
        row.update shop_id: row.mailing.shop_id
      end
    end
    add_index :digest_mailing_batches, :shop_id
    add_column :order_items, :shop_id, :integer
    OrderItem.all.each do |row|
      if row.order.nil?
        row.destroy
      else
        row.update shop_id: row.order.shop_id
      end
    end
    add_index :order_items, :shop_id
  end
end
