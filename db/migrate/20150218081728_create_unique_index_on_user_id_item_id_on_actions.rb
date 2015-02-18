class CreateUniqueIndexOnUserIdItemIdOnActions < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :actions, [:user_id, :item_id], unique: true, algorithm: :concurrently
  end
end
