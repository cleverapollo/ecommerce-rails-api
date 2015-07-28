class ChangeClientsIndex < ActiveRecord::Migration
  def change
    remove_index :clients,  name: :index_clients_on_shop_id_and_external_id
    add_index "clients", ["shop_id", "external_id"], where: "external_id IS NOT NULL"
  end
end
