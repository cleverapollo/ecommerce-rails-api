class RemoveUserIndexFromActions < ActiveRecord::Migration
  def up
    remove_index :actions, :user_id
  end

  def down
    add_index "actions", ["user_id"], name: "index_actions_on_user_id", using: :btree
  end
end
