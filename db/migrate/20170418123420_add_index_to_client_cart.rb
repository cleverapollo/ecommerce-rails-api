class AddIndexToClientCart < ActiveRecord::Migration
  def change
    add_index :client_carts, :shop_id
  end
end
