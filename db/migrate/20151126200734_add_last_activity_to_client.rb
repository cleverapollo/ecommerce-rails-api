class AddLastActivityToClient < ActiveRecord::Migration
  def change
    add_column :clients, :last_activity_at, :date
    add_index :clients, [:shop_id, :last_activity_at], where: "email IS NOT NULL AND triggers_enabled IS TRUE AND last_activity_at IS NOT NULL"
  end
end
