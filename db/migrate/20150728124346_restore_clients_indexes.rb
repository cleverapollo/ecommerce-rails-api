class RestoreClientsIndexes < ActiveRecord::Migration
  def change
    add_index "clients", ["shop_id"]
    add_index "clients", [:subscription_popup_showed, :shop_id]
    add_index "clients", [:triggers_enabled, :shop_id]
    add_index :clients, [:user_id]
  end
end
