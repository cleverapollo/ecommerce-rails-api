class AddReputationKeyToOrders < ActiveRecord::Migration
  def up
    add_column :orders, :reputation_key, :string

    Order.find_each do |order|
      order.update(reputation_key: Digest::MD5.hexdigest(order.id.to_s))
    end
  end

  def down
    remove_column :orders, :reputation_key
  end
end
