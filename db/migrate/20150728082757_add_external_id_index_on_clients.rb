class AddExternalIdIndexOnClients < ActiveRecord::Migration
  def change
    add_index "clients", ["shop_id", "external_id"]
  end
end
