class RestoreLostIndexes < ActiveRecord::Migration
  def change
    add_index :client_errors, :shop_id, where: "resolved = false"
  end
end
