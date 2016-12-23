class AddReputationKeyToOrders < ActiveRecord::Migration

  def up
    add_column :orders, :reputation_key, :string
  end

  def down
    remove_column :orders, :reputation_key
  end
end
