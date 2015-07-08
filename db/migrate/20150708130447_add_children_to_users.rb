class AddChildrenToUsers < ActiveRecord::Migration
  def change
    add_column :users, :children, :jsonb, default: '[]', null: false
  end
end
