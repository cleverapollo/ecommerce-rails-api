class AddReputationKeyToOrders < ActiveRecord::Migration

  def up
    puts "Problem migration"
    # add_column :orders, :reputation_key, :string

    # order_all = Order.count
    # order_counter = 0

    # Order.find_each do |order|
    #   order.update(reputation_key: Digest::MD5.hexdigest(order.id.to_s))
    #   order_counter += 1
    #   p "обработано #{order_counter} из #{order_all}"
    # end
  end

  def down
    remove_column :orders, :reputation_key
  end
end
