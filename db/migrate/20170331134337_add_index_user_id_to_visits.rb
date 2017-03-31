class AddIndexUserIdToVisits < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :visits, :user_id, algorithm: :concurrently
  end
end
